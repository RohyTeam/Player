import { batteryInfo, BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { fileIo, hash, picker } from '@kit.CoreFileKit';
import { convertNumberToDurationString } from '../../util/TimeUtil';
import { common } from '@kit.AbilityKit';
import { curves, display, LengthMetrics, window } from '@kit.ArkUI';
import { StringArray } from '../../entity/Arrays';
import { SubtitleLibraryDatabase } from '../../database/SubtitleLibraryDatabase';
import { FileUtil } from '@pura/harmony-utils';
import { showAlert } from '../../util/AlertUtil';
import { SubtitleEntity, Subtitles } from '../../entity/SubtitleEntity';
import { AudioEntity, Audios } from '../../entity/AudioEntity';
import { JSON } from '@kit.ArkTS';
import { compile } from '../../lib/ass_compiler';
import { AssSubtitleView } from '../subtitle/AssSubtitleView';
import { connectDevice, disconnectDevice } from '../../util/ContinueUtil';
import VideoAbility from '../../ability/VideoAbility';
import { BatteryInfo } from '../statusbar/info/BatteryInfo';
import { TimeInfo } from '../statusbar/info/TimeInfo';
import { StatusBar } from '../statusbar/StatusBar';
import { IjkMediaPlayer } from '@ohos/ijkplayer';
import { On } from '@ohos.UiTest';

@Observed
export class VideoState {
  @Track
  paused: boolean = false
}

enum SurfaceFillingMode {

  Stretch, Fit, FourByThree, SixteenByNine

}

interface MediaInfoType {
  audioDecoder: string
  videoDecoder: string
  meta: string
}

/**
 * 由原本的 AVPlayer 转移为 ijkPlayer
 */
@Component
export struct IjkVideoPlayer {
  @Prop
  @Require
  title: string
  @Prop
  @Require
  url: string
  @Prop
  @Require
  hash: string
  @Prop
  @Require
  videoHolder: string
  @Link
  backTrigger: boolean
  @Link
  isContinuation: boolean
  private ijkPlayer: IjkMediaPlayer | undefined = undefined
  @State
  private avPlayer: media.AVPlayer | undefined = undefined
  private xComponentController = new XComponentController()
  private videoPlayerGestureModifier = new VideoPlayerGestureModifier(
    () => {
      if (this.avPlayer) {
        if (this.avPlayer.state == "paused") {
          this.avPlayer.play()
          this.videoState.paused = false
        } else {
          this.avPlayer.pause()
          this.videoState.paused = true
        }
      }
    },
    () => {
      this.showControls = !this.showControls
    },
    () => {
      if (this.avPlayer) {
        this.avPlayer.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_3_00_X)
        this.speedingUp = true
      }
    },
    () => {
      if (this.avPlayer) {
        this.avPlayer.setSpeed(this.currentSpeed)
        this.speedingUp = false
      }
    },
    () => {
      this.adjustingBrightness = true
    },
    () => {
      this.adjustingBrightness = false
    },
    () => {
      this.adjustingVolume = true
    },
    () => {
      this.adjustingVolume = false
    },
    (value: number) => {
      this.surfaceBrightness = Math.max(0, Math.min(100, this.surfaceBrightness + value))
      VideoAbility.getWindow().setWindowBrightness(this.surfaceBrightness / 100)
    },
    (value: number) => {
      this.surfaceBrightness = Math.max(0, Math.min(100, this.surfaceBrightness - value))
      VideoAbility.getWindow().setWindowBrightness(this.surfaceBrightness / 100)
    },
    (value: number) => {
      this.surfaceVolume = Math.max(0, Math.min(100, this.surfaceVolume + value))
      this.avPlayer?.setVolume(this.surfaceVolume / 100)
    },
    (value: number) => {
      this.surfaceVolume = Math.max(0, Math.min(100, this.surfaceVolume - value))
      this.avPlayer?.setVolume(this.surfaceVolume / 100)
    }
  )
  @State
  private parameterStartTime: number = -1
  @State
  private parameterStartPaused: boolean | undefined = undefined
  @State
  private showControls: boolean = false
  @State
  private videoState: VideoState = new VideoState()
  @State
  private currentPosition: number = 0
  @State
  private max: number = 1
  @State
  private currentSpeed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X
  @State
  private surfaceFillingMode: SurfaceFillingMode = SurfaceFillingMode.Fit
  @State
  private speedingUp: boolean = false
  @State
  private movingPosition: number = 0
  @State
  private movingProgressBar: boolean = false
  @State
  private videoMetadata: media.AVMetadata | undefined = undefined
  @State
  private surfaceWidth: number = 0
  @State
  private surfaceHeight: number = 0
  @StorageProp("screenHeight")
  private screenHeight: number = 1
  @StorageProp("screenWidth")
  private screenWidth: number = 1
  @State
  private selectedSubtitle: number | undefined = undefined
  @State
  private availableSubtitles: Subtitles = []
  @State
  private selectedAudio: number | undefined = undefined
  @State
  private availableAudios: Audios = []
  @State
  private subtitleHashes: StringArray = []
  @State
  private adjustingBrightness: boolean = false
  @State
  private adjustingVolume: boolean = false
  @StorageLink('statusBar')
  settings$statusBar: boolean = false;
  @StorageLink('autoShutdown')
  @Watch("autoShutdownSwitchWatcher")
  autoShutdown: boolean = false;
  @StorageLink(`videoAbility_shouldDie`)
  @Watch("shouldDieWatcher")
  videoAbility_shouldDie: StringArray = [];

  @State
  private shouldReallyDie: boolean = false

  shouldDieWatcher(changedPropertyName: string) {
    this.shouldReallyDie = this.videoAbility_shouldDie.indexOf(this.hash) >= 0
  }

  autoShutdownSwitchWatcher(changedPropertyName: string) {
    if (this.autoShutdown) {
      if (!VideoAbility.getWindow().isFocused()) {
        if (!this.backTrigger) {
          this.backTrigger = true
          this.ijkPlayer?.pause()
          this.ijkPlayer?.stop()
          this.ijkPlayer?.release()
          this.avPlayer?.pause()
          this.avPlayer?.release()
            .then(() => {
              if (this.url.startsWith("dfs:")) {
                disconnectDevice(this.videoHolder)
                  .then(() => {
                    VideoAbility.getContext().terminateSelf()
                      .then(() => {
                        let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
                        let index = shouldDies.indexOf(this.hash)
                        if (index >= 0) {
                          shouldDies.slice(index, 1)
                          AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
                        }
                      })
                  })
              } else {
                VideoAbility.getContext().terminateSelf()
                  .then(() => {
                    let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
                    let index = shouldDies.indexOf(this.hash)
                    if (index >= 0) {
                      shouldDies.slice(index, 1)
                      AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
                    }
                  })
              }
            })
        }
      }
    }
  }

  build() {
    Stack() {
      Column() {
        Column() {
          if (this.settings$statusBar) {
            this.statusBar()
          }
          this.topBar()
        }
        .borderRadius({
          bottomLeft: 16,
          bottomRight: 16
        })
        .backgroundColor($r("app.color.comp_background_focus"))
        .visibility(this.showControls ? Visibility.Visible : Visibility.Hidden)
        .animation({
          curve: curves.springMotion()
        })
        .transition(
          TransitionEffect.asymmetric(
            TransitionEffect.move(TransitionEdge.TOP),
            TransitionEffect.move(TransitionEdge.TOP)
          )
        )

        this.surfaceOverlay()
        Column() {
          this.progressBar()
          this.bottomBar()
        }
        .backgroundColor($r("app.color.comp_background_focus"))
        .visibility(this.showControls ? Visibility.Visible : Visibility.Hidden)
        .animation({
          curve: curves.springMotion()
        })
        .borderRadius({
          topLeft: 16,
          topRight: 16
        })
        .transition(
          TransitionEffect.asymmetric(
            TransitionEffect.move(TransitionEdge.BOTTOM),
            TransitionEffect.move(TransitionEdge.BOTTOM)
          )
        )
        .width("100%")
      }
      .visibility(this.showControls ? Visibility.Visible : Visibility.Hidden)
      .animation({
        curve: curves.springMotion()
      })
      .transition(TransitionEffect.OPACITY)
      .width("100%")
      .height("100%")
      .zIndex(100) // 由于字幕也有分层，把 zIndex 设置高一点防止被字母遮挡
      Stack() {
        if (this.speedingUp) {
          Stack() {
            Text($r("app.string.long_press_speeding_up"))
              .fontSize(32)
              .fontColor("#ffffffff")
          }
          .backgroundColor("#88000000")
          .alignContent(Alignment.Center)
          .width("100%")
          .height("100%")
        }
        if (this.adjustingBrightness) {
          Stack() {
            Text($r("app.string.adjusting_brightness", this.surfaceBrightness))
              .fontSize(32)
              .fontColor("#ffffffff")
          }
          .backgroundColor("#88000000")
          .alignContent(Alignment.Center)
          .width("100%")
          .height("100%")
        }
        if (this.adjustingVolume) {
          Stack() {
            Text($r("app.string.adjusting_volume", this.surfaceVolume))
              .fontSize(32)
              .fontColor("#ffffffff")
          }
          .backgroundColor("#88000000")
          .alignContent(Alignment.Center)
          .width("100%")
          .height("100%")
        }
        if (this.movingProgressBar) {
          Stack() {
            Text(`${convertNumberToDurationString(this.movingPosition)}/${convertNumberToDurationString(this.max)}`)
              .fontSize(32)
              .fontColor("#ffffffff")
          }
          .backgroundColor("#88000000")
          .alignContent(Alignment.Center)
          .width("100%")
          .height("100%")
        }
      }
      .alignContent(Alignment.Center)
      .gestureModifier(this.videoPlayerGestureModifier)
      .width("100%")
      .height("100%")
      .zIndex(99) // 由于字幕也有分层，把 zIndex 设置高一点防止被字幕遮挡

      Stack() {
        Stack() {
          if (this.selectedSubtitle != undefined) {
            AssSubtitleView({
              subtitle: this.availableSubtitles[this.selectedSubtitle].compiledASS,
              actualWidth: this.calculateWidth(this.surfaceFillingMode),
              actualHeight: this.calculateHeight(this.surfaceFillingMode),
              currentTime: this.currentPosition
            })
              .onAppear(() => {
                console.error("showing subtitle!")
              })
          }
        }
        .height(this.calculateHeightPercent(this.surfaceFillingMode))
        .width(this.calculateWidthPercent(this.surfaceFillingMode))
      }
      .alignContent(Alignment.Center)
      .width("100%")
      .height("100%")
      .zIndex(20)

      Stack() {
        XComponent({
          id: `ijkvideoplayer_${this.hash}`,
          type: XComponentType.SURFACE,
          libraryname: 'ijkplayer_napi',
          controller: this.xComponentController
        })
          .onLoad((context) => {
            if (context != undefined) {
              console.error(`about to appear`)
              VideoAbility.getWindow().setWindowBrightness(0.5)
              if (this.isContinuation) {
                this.parameterStartTime = AppStorage.get("videoPosition") || -1
                this.parameterStartPaused = AppStorage.get("videoPaused") || undefined
              }
              this.initIjkPlayer(context, `ijkvideoplayer_${this.hash}`)
            }
          })
          .height(this.calculateHeightPercent(this.surfaceFillingMode))
          .width(this.calculateWidthPercent(this.surfaceFillingMode))
      }
      .rotate({
        y: 1,
        centerX: "50%",
        centerY: "50%",
        angle: this.mirrorClip ? '180deg' : '0deg'
      })
      .backgroundColor(Color.Black)
      .alignContent(Alignment.Center)
      .width("100%")
      .height("100%")
      .zIndex(-100) // 由于字幕也有分层，把 zIndex 设置小一点防止遮挡字幕
      if (this.shouldReallyDie) {
        Stack() { // 自动关闭设置专用
        }
        .onAppear(() => {
          if (this.autoShutdown) {
            console.error('detected auto shutdown, shutting down')
            this.backTrigger = true
            if (this.url.startsWith("dfs:")) {
              disconnectDevice(this.videoHolder)
                .then(() => {
                  VideoAbility.getContext().terminateSelf()
                    .then(() => {
                      let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
                      let index = shouldDies.indexOf(this.hash)
                      if (index >= 0) {
                        shouldDies.slice(index, 1)
                        AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
                      }
                    })
                })
            } else {
              VideoAbility.getContext().terminateSelf()
                .then(() => {
                  let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
                  let index = shouldDies.indexOf(this.hash)
                  if (index >= 0) {
                    shouldDies.slice(index, 1)
                    AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
                  }
                })
            }
          }
        })
        .zIndex(101)
      }
    }
    .width("100%")
    .height("100%")
  }

  @State
  private repeatPlay: boolean = false
  @State
  private mirrorClip: boolean = false

  @StorageLink('statusBarBatteryPercent')
  statusBarBatteryPercent: boolean = false;

  @Builder
  private statusBar() {
    Row() {
      StatusBar({
        statusBarBatteryPercent: this.statusBarBatteryPercent
      })
    }
    .padding({
      left: 16,
      right: 16,
      top: 8
    })
    .backgroundColor($r("app.color.comp_background_focus"))
    .alignItems(VerticalAlign.Center)
    .width("100%")
  }

  /**
   * 播放器控制器的上方显示内容
   */
  @Builder
  private topBar() {
    Row() {
      this.leftAlignedCircleButton(
        $r("sys.symbol.chevron_left"),
        () => {
          this.backTrigger = true
          if (this.url.startsWith("dfs:")) {
            disconnectDevice(this.videoHolder)
              .then(() => {
                VideoAbility.getContext().terminateSelf()
                  .then(() => {
                    let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
                    let index = shouldDies.indexOf(this.hash)
                    if (index >= 0) {
                      shouldDies.slice(index, 1)
                      AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
                    }
                  })
              })
          } else {
            VideoAbility.getContext().terminateSelf()
              .then(() => {
                let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
                let index = shouldDies.indexOf(this.hash)
                if (index >= 0) {
                  shouldDies.slice(index, 1)
                  AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
                }
              })
          }
        }
      )
      Text(this.title)
        .maxLines(1)
        .textOverflow({
          overflow: TextOverflow.MARQUEE
        })
        .margin({
          left: 4,
          right: 4
        })
        .layoutWeight(2)
        .fontColor($r("app.color.font_primary"))
      TopBar_RightAlignedCircleSwitch({
        icon: $r("sys.symbol.repeat"),
        switchValue: $repeatPlay,
      })
      TopBar_RightAlignedCircleSwitch({
        icon: $r("sys.symbol.trapezoid_and_line_vertical"),
        switchValue: $mirrorClip,
      })
      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.slider_horizontal_2"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        left: 12
      })
      .width(40)
      .height(40)
      .bindMenu(this.slidersMenus, { backgroundColor: $r("app.color.menus_background"), backgroundBlurStyle: BlurStyle.NONE })
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor($r("app.color.comp_background_focus"))
    .alignItems(VerticalAlign.Center)
    //.height("15%")
    .width("100%")
    .borderRadius({
      bottomLeft: 16,
      bottomRight: 16
    })
  }

  /**
   * 播放器控制器中间留空显示未被遮挡视频内容的部分
   */
  @Builder
  private surfaceOverlay() {
    Row() {
      Row() {

      }
      .layoutWeight(1)

      Row() {

      }
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .layoutWeight(1)
    .gestureModifier(this.videoPlayerGestureModifier)
    .visibility(
      this.showControls ? Visibility.Visible : Visibility.Hidden
    )
  }

  /**
   * 播放器控制器的进度条
   */
  @Builder
  private progressBar() {
    Row() {
      Text(`${convertNumberToDurationString(this.currentPosition)}`)
        .margin({
          left: 16,
          right: 4
        })
        .fontColor($r("app.color.font_secondary"))
      Slider({
        min: 0,
        max: this.max,
        step: 1,
        value: this.currentPosition
      })
        .onChange((value, mode: SliderChangeMode) => {
          if (mode == SliderChangeMode.Begin) {
            this.movingProgressBar = true
            this.movingPosition = value
          } else if (mode == SliderChangeMode.Moving) {
            this.movingPosition = value
          } else if (mode == SliderChangeMode.End || mode == SliderChangeMode.Click) {
            this.movingProgressBar = false
            this.currentPosition = value
            this.avPlayer?.seek(value, media.SeekMode.SEEK_CLOSEST)
          }
        })
        .layoutWeight(1)
      Text(`${convertNumberToDurationString(this.max)}`)
        .margin({
          left: 4,
          right: 16
        })
        .fontColor($r("app.color.font_secondary"))
    }
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
    .backgroundColor($r("app.color.comp_background_focus"))
    .alignItems(VerticalAlign.Center)
    .width("100%")
  }

  /**
   * 播放器控制器的下方显示内容
   */
  @Builder
  private bottomBar() {
    Row() {
      this.leftAlignedCircleButton(
        $r("sys.symbol.gobackward_10"),
        () => {
          this.avPlayer?.seek(Math.max(0, this.currentPosition - 10 * 1000), media.SeekMode.SEEK_CLOSEST)
        }
      )
      Button({
        type: ButtonType.Circle
      }) {
        if (!this.videoState.paused) {
          SymbolGlyph($r("sys.symbol.pause"))
            .fontSize(24)
            .fontColor([$r("app.color.icon_primary")])
        } else {
          SymbolGlyph($r("sys.symbol.play_fill"))
            .fontSize(24)
            .fontColor([$r("app.color.icon_primary")])
        }
      }
      .align(Alignment.Center)
      .margin({
        right: 12
      })
      .width(40)
      .height(40)
      .onClick(() => {
        if (this.avPlayer) {
          if (this.avPlayer.state == "paused") {
            this.avPlayer.play()
            this.videoState.paused = false
          } else if (this.avPlayer.state == "completed") {
            this.currentPosition = 0
            this.avPlayer.seek(0, media.SeekMode.SEEK_CLOSEST)
            this.avPlayer.play()
            this.videoState.paused = false
          } else if (this.avPlayer.state == "playing") {
            this.avPlayer.pause()
            this.videoState.paused = true
          }
        }
      })
      .backgroundColor($r("app.color.comp_background_tertiary"))

      this.leftAlignedCircleButton(
        $r("sys.symbol.goforward_10"),
        () => {
          this.avPlayer?.seek(Math.min(this.max, this.currentPosition + 10 * 1000), media.SeekMode.SEEK_CLOSEST)
        }
      )

      Blank()
        .layoutWeight(1)

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.rectangle"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        left: 12
      })
      .width(40)
      .height(40)
      .bindMenu(this.surfaceFillingModeMenus, { backgroundColor: $r("app.color.menus_background"), backgroundBlurStyle: BlurStyle.NONE })
      .backgroundColor($r("app.color.comp_background_tertiary"))

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.timer"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        left: 12
      })
      .width(40)
      .height(40)
      .bindMenu(this.speedMenus, { backgroundColor: $r("app.color.menus_background"), backgroundBlurStyle: BlurStyle.NONE })
      .backgroundColor($r("app.color.comp_background_tertiary"))

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.speaker_wave_3"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        left: 12
      })
      .width(40)
      .height(40)
      .bindMenu(this.audioMenus, { backgroundColor: $r("app.color.menus_background"), backgroundBlurStyle: BlurStyle.NONE })
      .backgroundColor($r("app.color.comp_background_tertiary"))

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.textformat"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        left: 12
      })
      .width(40)
      .height(40)
      .bindMenu(this.subtitleMenus, { backgroundColor: $r("app.color.menus_background"), backgroundBlurStyle: BlurStyle.NONE })
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .padding({
      left: 16,
      right: 16,
      bottom: 12
    })
    .backgroundColor($r("app.color.comp_background_focus"))
    .alignItems(VerticalAlign.Center)
    //.height("15%")
    .width("100%")
  }

  @Builder
  private leftAlignedCircleButton(
    icon: Resource,
    onClick: () => void
  ) {
    Button({
      type: ButtonType.Circle
    }) {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([$r("app.color.icon_primary")])
    }
    .align(Alignment.Center)
    .margin({
      right: 12
    })
    .width(40)
    .height(40)
    .onClick(() => {
      onClick()
    })
    .backgroundColor($r("app.color.comp_background_tertiary"))
  }

  @Builder
  private rightAlignedCircleButton(
    icon: Resource,
    onClick: () => void
  ) {
    Button({
      type: ButtonType.Circle
    }) {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([$r("app.color.icon_primary")])
    }
    .align(Alignment.Center)
    .margin({
      left: 12
    })
    .width(40)
    .height(40)
    .onClick(() => {
      onClick()
    })
    .backgroundColor($r("app.color.comp_background_tertiary"))
  }

  @State
  private surfaceBrightness: number = 50
  @State
  private surfaceVolume: number = 100

  @Builder
  slidersMenus() {
    Column() {
      Row() {
        SymbolGlyph($r("sys.symbol.sun_max"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
          .margin({
            left: 12
          })
        Slider({
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.InSet,
          value: this.surfaceBrightness,
        })
          .onChange((value: number) => {
            this.surfaceBrightness = value
            VideoAbility.getWindow().setWindowBrightness(value / 100)
          })
          .width("192vp")
          .margin({
            right: 8
          })
      }

      Row() {
        SymbolGlyph($r("sys.symbol.speaker_wave_3"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
          .margin({
            left: 12
          })
        Slider({
          min: 0,
          max: 100,
          step: 1,
          style: SliderStyle.InSet,
          value: this.surfaceVolume,
        })
          .onChange((value: number) => {
            this.surfaceVolume = value
            this.avPlayer?.setVolume(value / 100)
          })
          .width("192vp")
          .margin({
            right: 8
          })
      }
    }
  }

  @Builder
  subtitleMenus() {
    Menu() {
      MenuItemGroup() {
        MenuItem() {
          Row() {
            Text($r("app.string.no_subtitle"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.selectedSubtitle == undefined ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.selectedSubtitle = undefined
        })
        .margin({
          top: 4,
          left: 4,
          right: 4
        })
        ForEach(this.availableSubtitles, (subtitle: SubtitleEntity, index: number) => {
          MenuItem() {
            Row() {
              Text(`${subtitle.name} (${subtitle.language})`)
                .fontWeight(FontWeight.Medium)
                .margin(12)
              Blank()
                .width("76vp")
              SymbolGlyph($r("sys.symbol.checkmark"))
                .fontColor([$r("app.color.icon_primary")])
                .visibility(this.selectedSubtitle == subtitle.index ? Visibility.Visible : Visibility.Hidden)
                .margin(12)
                .fontSize(24)
            }
            .alignItems(VerticalAlign.Center)
          }
          .onClick(() => {
            this.selectedSubtitle = index
          })
          .margin({
            left: 4,
            right: 4
          })
        })
        MenuItem()
          .margin({
            bottom: "8vp"
          })
      }

      MenuItemGroup() {
        MenuItem()
        MenuItem({
          content: $r("app.string.import_video")
        })
          .onClick(() => {
            this.showSubtitlePicker()
          })
          .margin({
            bottom: 4,
            left: 4,
            right: 4
          })
      }
    }
    .menuItemDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
    })
    .menuItemGroupDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(8),
      startMargin: LengthMetrics.vp(0),
      endMargin: LengthMetrics.vp(0)
    })
    .padding(0)
  }

  @Builder
  audioMenus() {
    Menu() {
      MenuItemGroup() {
        ForEach(this.availableAudios, (audio: AudioEntity, index: number) => {

          MenuItem() {
            Row() {
              Text(`${audio.name} (${audio.language})`)
                .fontWeight(FontWeight.Medium)
                .margin(12)
              Blank()
                .width("76vp")
              SymbolGlyph($r("sys.symbol.checkmark"))
                .fontColor([$r("app.color.icon_primary")])
                .visibility(this.selectedAudio == audio.index ? Visibility.Visible : Visibility.Hidden)
                .margin(12)
                .fontSize(24)
            }
            .alignItems(VerticalAlign.Center)
          }
          .onClick(() => {
            if (this.selectedSubtitle != undefined) {
              this.avPlayer?.deselectTrack(this.selectedAudio)
              this.selectedAudio = undefined
            }
            this.avPlayer?.selectTrack(audio.index)
            this.selectedAudio = audio.index
          })
          .margin(
            index == 0 ? (
              this.availableAudios.length == 1 ? {
                top: 4,
                bottom: 4,
                left: 4,
                right: 4
              } : {
                top: 4,
                left: 4,
                right: 4
              }
            ) : (index == this.availableSubtitles.length - 1 ? {
              bottom: 4,
              left: 4,
              right: 4
            } : {
              left: 4,
              right: 4
            })
          )
        })
      }
    }
    .menuItemDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
    })
    .padding(0)
  }

  @Builder
  surfaceFillingModeMenus() {
    Menu() {
      MenuItemGroup() {
        MenuItem() {
          Row() {
            Text($r("app.string.surfaceFillingMode_fit"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.surfaceFillingMode == SurfaceFillingMode.Fit ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.surfaceFillingMode = SurfaceFillingMode.Fit
        })
        .margin({
          top: 4,
          left: 4,
          right: 4
        })
        MenuItem() {
          Row() {
            Text($r("app.string.surfaceFillingMode_stretch"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.surfaceFillingMode == SurfaceFillingMode.Stretch ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.surfaceFillingMode = SurfaceFillingMode.Stretch
        })
        .margin({
          left: 4,
          right: 4
        })
        MenuItem() {
          Row() {
            Text($r("app.string.surfaceFillingMode_4by3"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.surfaceFillingMode == SurfaceFillingMode.FourByThree ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.surfaceFillingMode = SurfaceFillingMode.FourByThree
        })
        .margin({
          left: 4,
          right: 4
        })
        MenuItem() {
          Row() {
            Text($r("app.string.surfaceFillingMode_16by9"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.surfaceFillingMode == SurfaceFillingMode.SixteenByNine ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.surfaceFillingMode = SurfaceFillingMode.SixteenByNine
        })
        .margin({
          bottom: 4,
          left: 4,
          right: 4
        })
      }
    }
    .menuItemDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
    })
    .padding(0)
  }

  @Builder
  speedMenus() {
    Menu() {
      MenuItemGroup() {
        MenuItem() {
          Row() {
            Text("0.50x")
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_0_50_X ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_0_50_X)
        })
        .margin({
          left: 4,
          right: 4,
          top: 4
        })
        MenuItem() {
          Row() {
            Text("0.75x")
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_0_75_X ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_0_75_X)
        })
        .margin({
          left: 4,
          right: 4
        })
        MenuItem() {
          Row() {
            Text("1.00x")
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_1_00_X ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X)
        })
        .margin({
          left: 4,
          right: 4
        })
        MenuItem() {
          Row() {
            Text("1.25x")
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_1_25_X ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_25_X)
        })
        .margin({
          left: 4,
          right: 4
        })
        MenuItem() {
          Row() {
            Text("1.50x")
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_1_50_X ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_50_X)
        })
        .margin({
          left: 4,
          right: 4
        })
        MenuItem() {
          Row() {
            Text("1.75")
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_1_75_X ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_75_X)
        })
        .margin({
          left: 4,
          right: 4
        })
        MenuItem() {
          Row() {
            Text("2.00x")
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("76vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_2_00_X ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_2_00_X)
        })
        .margin({
          left: 4,
          right: 4,
          bottom: 4
        })
      }
    }
    .menuItemDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
    })
    .padding(0)
  }

  aboutToAppear(): void {
    console.error(`received screen width & height: ${this.screenWidth}, ${this.screenHeight}`)
  }

  aboutToDisappear(): void {
    if (!this.backTrigger) {
      this.backTrigger = true
      this.ijkPlayer?.pause()
      this.ijkPlayer?.stop()
      this.ijkPlayer?.release()
      this.avPlayer?.pause()
      this.avPlayer?.release()
        .then(() => {
          if (this.url.startsWith("dfs:")) {
            disconnectDevice(this.videoHolder)
              .then(() => {
                VideoAbility.getContext().terminateSelf()
                  .then(() => {
                    let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
                    let index = shouldDies.indexOf(this.hash)
                    if (index >= 0) {
                      shouldDies.slice(index, 1)
                      AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
                    }
                  })
              })
          } else {
            VideoAbility.getContext().terminateSelf()
              .then(() => {
                let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
                let index = shouldDies.indexOf(this.hash)
                if (index >= 0) {
                  shouldDies.slice(index, 1)
                  AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
                }
              })
          }
        })
    } else {
      this.ijkPlayer?.pause()
      this.ijkPlayer?.stop()
      this.ijkPlayer?.release()
      this.avPlayer?.pause()
      this.avPlayer?.release()
    }
  }

  private updateSpeed(speed: media.PlaybackSpeed) {
    this.currentSpeed = speed
    this.avPlayer?.setSpeed(speed)
  }

  private showSubtitlePicker() {
    let documentViewPicker = new picker.DocumentViewPicker(this.getUIContext().getHostContext()!);
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 10; // 太多了处理不过来
    documentSelectOptions.fileSuffixFilters = ['ass 字幕文件|.ass'];

    documentViewPicker.select(documentSelectOptions)
      .then((documentSelectResult: Array<string>) => {
        if (documentSelectResult.length == 0) {
          return
        }

        hash.hash(FileUtil.getFilePath(this.url), "sha256")
          .then(async (fileHash) => {
            let duplicated = false
            for (let fileUrl of documentSelectResult) {
              let hashValue = await hash.hash(FileUtil.getFilePath(fileUrl), "sha256")
              if (this.subtitleHashes.indexOf(hashValue) >= 0) {
                duplicated = true
              } else {
                SubtitleLibraryDatabase.add(getContext(this), fileHash, fileUrl)
                  .then((tuple) => {
                    fileIo.open(tuple[0])
                      .then((subtitleFile) => {
                        fileIo.readText(subtitleFile.path)
                          .then((readText) => {
                            let compiledASS = compile(readText, void 0)
                            let fileName = FileUtil.getFileName(fileUrl)
                            this.subtitleHashes.push(tuple[1])
                            this.availableSubtitles.push({
                              index: this.availableSubtitles.length,
                              name: compiledASS.info.Title || fileName.substring(0, fileName.length - 4),
                              language: "Ukn",
                              compiledASS: compiledASS
                            })
                          })
                      })
                  })
              }
            }

            if (duplicated) {
              showAlert(this.getUIContext(), $r("app.string.duplicated_imports"),
                $r("app.string.duplicated_imports_desc"))
            }
          })
      }).catch((err: BusinessError) => {
      console.error(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
    })
  }

  private findMetadata(uri: string): Promise<media.AVMetadata> {
    return new Promise((resultReturner) => {
      media.createAVMetadataExtractor().then((avMetadataExtractor: media.AVMetadataExtractor) => {
        fileIo.open(uri)
          .then((file) => {
            avMetadataExtractor.fdSrc = { fd: file.fd }
            avMetadataExtractor.fetchMetadata()
              .then((metadata) => {
                avMetadataExtractor.release()
                resultReturner(metadata)
              })
          })
      })
    })
  }

  private calculateWidth(surfaceFillingMode: SurfaceFillingMode): number {
    if (surfaceFillingMode == SurfaceFillingMode.Stretch) {
      return this.screenWidth
    } else if (surfaceFillingMode == SurfaceFillingMode.FourByThree) {
      if ((this.screenHeight / this.screenWidth) > (3 / 4)) {
        return this.screenWidth
      } else {
        return this.screenHeight / 3 * 4
      }
    } else if (surfaceFillingMode == SurfaceFillingMode.SixteenByNine) {
      if ((this.screenHeight / this.screenWidth) > (9 / 16)) {
        return this.screenWidth
      } else {
        return this.screenHeight / 9 * 16
      }
    } else {
      if ((this.surfaceHeight / this.surfaceWidth) > (this.screenHeight / this.screenWidth)) {
        return this.screenHeight / this.surfaceHeight * this.surfaceWidth
      } else {
        return this.screenWidth
      }
    }
  }

  private calculateHeight(surfaceFillingMode: SurfaceFillingMode): number {
    if (surfaceFillingMode == SurfaceFillingMode.Stretch) {
      return this.screenHeight
    } else if (surfaceFillingMode == SurfaceFillingMode.FourByThree) {
      if ((this.screenHeight / this.screenWidth) > (3 / 4)) {
        return this.screenWidth / 4 * 3
      } else {
        return this.screenHeight
      }
    } else if (surfaceFillingMode == SurfaceFillingMode.SixteenByNine) {
      if ((this.screenHeight / this.screenWidth) > (9 / 16)) {
        return this.screenWidth / 16 * 9
      } else {
        return this.screenHeight
      }
    } else {
      if ((this.surfaceHeight / this.surfaceWidth) > (this.screenHeight / this.screenWidth)) {
        return this.screenHeight
      } else {
        return this.screenWidth / this.surfaceWidth * this.surfaceHeight
      }
    }
  }

  private calculateWidthPercent(surfaceFillingMode: SurfaceFillingMode): string {
    if (this.surfaceWidth <= 0) {
      console.error(`width percent fallback to 100%`)
      return "100%"
    }
    if (surfaceFillingMode == SurfaceFillingMode.Stretch) {
      return "100%"
    } else if (surfaceFillingMode == SurfaceFillingMode.FourByThree) {
      if ((this.screenHeight / this.screenWidth) > (3 / 4)) {
        return "100%"
      } else {
        return `${((this.screenHeight / 3 * 4) / this.screenWidth) * 100}%`
      }
    } else if (surfaceFillingMode == SurfaceFillingMode.SixteenByNine) {
      if ((this.screenHeight / this.screenWidth) > (9 / 16)) {
        return "100%"
      } else {
        return `${((this.screenHeight / 9 * 16) / this.screenWidth) * 100}%`
      }
    } else {
      if ((this.surfaceHeight / this.surfaceWidth) == (this.screenHeight / this.screenWidth)) {
        return "100%"
      } else if ((this.surfaceHeight / this.surfaceWidth) > (this.screenHeight / this.screenWidth)) {
        console.error(`width percent: ${`${((this.screenHeight / this.surfaceHeight * this.surfaceWidth) / this.screenWidth) * 100}%`}`)
        return `${((this.screenHeight / this.surfaceHeight * this.surfaceWidth) / this.screenWidth) * 100}%`
      } else {
        return "100%"
      }
    }
  }

  private calculateHeightPercent(surfaceFillingMode: SurfaceFillingMode): string {
    if (this.surfaceHeight <= 0) {
      console.error(`height percent fallback to 100%`)
      return "100%"
    }
    if (surfaceFillingMode == SurfaceFillingMode.Stretch) {
      return "100%"
    } else if (surfaceFillingMode == SurfaceFillingMode.FourByThree) {
      if ((this.screenHeight / this.screenWidth) > (3 / 4)) {
        return `${((this.screenWidth / 4 * 3) / this.screenHeight) * 100}%`
      } else {
        return "100%"
      }
    } else if (surfaceFillingMode == SurfaceFillingMode.SixteenByNine) {
      if ((this.screenHeight / this.screenWidth) > (9 / 16)) {
        return `${((this.screenWidth / 16 * 9) / this.screenHeight) * 100}%`
      } else {
        return "100%"
      }
    } else {
      if ((this.surfaceHeight / this.surfaceWidth) == (this.screenHeight / this.screenWidth)) {
        return "100%"
      } else if ((this.surfaceHeight / this.surfaceWidth) > (this.screenHeight / this.screenWidth)) {
        return "100%"
      } else {
        console.error(`height percent: ${`${((this.surfaceHeight / this.surfaceWidth * this.screenWidth) /
        this.screenHeight) * 100}%`}`)
        return `${((this.surfaceHeight / this.surfaceWidth * this.screenWidth) / this.screenHeight) * 100}%`
      }
    }
  }

  private initIjkPlayer(context: Object, id: string) {
    console.error(`initing ijk player`)
    let finderUrl = this.url
    if (finderUrl.startsWith("dfs:")) {
      finderUrl = finderUrl.substring(4)
      connectDevice(this.videoHolder)
        .then(() => {
          console.error("connected to another device file system")
          this.findMetadata(finderUrl)
            .then((videoMetadata) => {
              this.videoMetadata = videoMetadata
              this.surfaceWidth = parseInt(this.videoMetadata.videoWidth!)
              this.surfaceHeight = parseInt(this.videoMetadata.videoHeight!)
              console.error(`surface width is: ${this.surfaceWidth}, height is: ${this.surfaceHeight}`)
              this.createIjkPlayer(context, id)
                .then(() => {

                })
            })
        })
        .catch((error: BusinessError) => {
          console.error(`error when connect file system: ${JSON.stringify(error)}`)
        })
    } else {
      this.findMetadata(finderUrl)
        .then((videoMetadata) => {
          this.videoMetadata = videoMetadata
          this.surfaceWidth = parseInt(this.videoMetadata.videoWidth!)
          this.surfaceHeight = parseInt(this.videoMetadata.videoHeight!)
          console.error(`surface width is: ${this.surfaceWidth}, height is: ${this.surfaceHeight}`)
          this.createIjkPlayer(context, id)
            .then(() => {

            })
        })
    }
  }

  private async createIjkPlayer(context: Object, id: string) {
    let ijkPlayer = new IjkMediaPlayer()
    this.ijkPlayer = ijkPlayer

    ijkPlayer.setContext(context, id)
    ijkPlayer.setDebug(true)
    ijkPlayer.native_setup();

    if (this.url.startsWith("file://media")) {
      console.error("opening file")
      let file = fileIo.openSync(this.url)
      ijkPlayer.setDataSource(file.path)
    } else if (this.url.startsWith("file://")) {
      console.error("hashing video")
      let fileHash = await hash.hash(FileUtil.getFilePath(this.url), "sha256")
      let file = fileIo.openSync(this.url)
      let subtitleUris = await SubtitleLibraryDatabase.get(getContext(this), fileHash)
      ijkPlayer.setDataSource(file.path)
      subtitleUris.forEach(subtitleUrl => {
        fileIo.open(subtitleUrl)
          .then((subtitleFile) => {
            hash.hash(subtitleFile.path, "sha256")
              .then((subtitleHash) => {
                fileIo.readText(subtitleFile.path)
                  .then((readText) => {
                    let compiledASS = compile(readText, void 0)
                    let fileName = FileUtil.getFileName(subtitleUrl)
                    this.subtitleHashes.push(subtitleHash)
                    this.availableSubtitles.push({
                      index: this.availableSubtitles.length,
                      name: compiledASS.info.Title || fileName.substring(0, fileName.length - 4),
                      language: "Ukn",
                      compiledASS: compiledASS
                    })
                  })
              })
          })
      })
    } else if (this.url.startsWith("dfs:")) {
      console.error("opening file")
      let file = fileIo.openSync(this.url.substring(4))
      ijkPlayer.setDataSource(file.path)
    }

    // options
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "enable-accurate-seek", "1")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max-buffer-size", "102400")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "min-frames", "120")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", "1")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", "0")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", "5")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max_cached_duration", "5000")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "infbuf", "1")

    // ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-all-videos", "1");
    // ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-hevc", "1");

    // timeout
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "timeout", "10000000");
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "connect_timeout", "10000000");
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "listen_timeout", "10000000");
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "addrinfo_timeout", "10000000");
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_timeout", "10000000");

    ijkPlayer.setOnSeekCompleteListener({
      onSeekComplete: () => {

      }
    })

    ijkPlayer.setOnPreparedListener({
      onPrepared: () => {
        let mediaInfoType = ijkPlayer.getMediaInfo() as MediaInfoType
        console.error(`what u want is: ${mediaInfoType.meta}`)

        if (this.parameterStartTime != -1) {
          ijkPlayer.seekTo(`${this.parameterStartTime}`)
        }
        if (this.parameterStartPaused != undefined && this.parameterStartPaused) {
          this.videoState.paused = true
          ijkPlayer.pause()
          AppStorage.setOrCreate("videoPaused", false)
        } else {
          this.videoState.paused = false
          ijkPlayer.start()
          AppStorage.setOrCreate("videoPaused", true)
        }
      }
    })

    ijkPlayer.setOnCompletionListener({
      onCompletion: () => {
        if (this.repeatPlay) {
          this.currentPosition = 0
          ijkPlayer.seekTo('0')
          ijkPlayer.start()
          this.videoState.paused = false
        } else {
          this.videoState.paused = true
          ijkPlayer.pause()
        }
        AppStorage.setOrCreate("videoPaused", true)
      }
    })

    ijkPlayer.setMessageListener();
    ijkPlayer.prepareAsync();
    ijkPlayer.start();
  }

  private createAvPlayer() {
    media.createAVPlayer()
      .then((avPlayer: media.AVPlayer) => {
        this.avPlayer = avPlayer
        avPlayer.on("timeUpdate", (time: number) => {
          this.currentPosition = time
          if (!this.movingProgressBar) {
            this.movingPosition = time
          }
          AppStorage.setOrCreate("videoPosition", time)
        })
        avPlayer.on('seekDone', (seekDoneTime: number) => {
          this.currentPosition = seekDoneTime
          if (!this.movingProgressBar) {
            this.movingPosition = seekDoneTime
          }
          AppStorage.setOrCreate("videoPosition", seekDoneTime)
        });
        avPlayer.on("durationUpdate", (duration: number) => {
          this.max = duration
        })
        avPlayer.on("stateChange", (state: string, reason: media.StateChangeReason) => {
          if (state == "paused") {
            console.error("paused")
            this.videoState.paused = true
            AppStorage.setOrCreate("videoPaused", true)
          } else if (state == "completed") {
          } else if (state == "playing") {
            console.error("playing")
            this.videoState.paused = false
            AppStorage.setOrCreate("videoPaused", false)
          } else if (state == "idle") {
            console.error("idle")
            this.videoState.paused = true
            AppStorage.setOrCreate("videoPaused", true)
            avPlayer.pause()
          } else if (state == "initialized") {
            console.error("initialized")
            avPlayer.surfaceId = this.xComponentController.getXComponentSurfaceId()
            avPlayer.prepare();
          } else if (state == "prepared") {
            console.error("prepared")
            if (this.parameterStartTime != -1) {
              avPlayer.seek(this.parameterStartTime, media.SeekMode.SEEK_CLOSEST)
            }
            if (this.parameterStartPaused != undefined && this.parameterStartPaused) {
              this.videoState.paused = true
              avPlayer.pause()
              AppStorage.setOrCreate("videoPaused", false)
            } else {
              this.videoState.paused = false
              avPlayer.play();
              AppStorage.setOrCreate("videoPaused", true)
            }
            avPlayer.getTrackDescription()
              .then((trackDescriptions) => {
                this.subtitleHashes = []
                let audioTracks: number[] = []
                trackDescriptions.forEach((trackDescription) => {
                  console.error(`track description: ${
                  JSON.stringify(
                    [
                      trackDescription[media.MediaDescriptionKey.MD_KEY_TRACK_INDEX],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_TRACK_TYPE],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_CODEC_MIME],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_DURATION],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_BITRATE],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_WIDTH],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_HEIGHT],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_FRAME_RATE],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_AUD_CHANNEL_COUNT],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_AUD_SAMPLE_RATE],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_AUD_SAMPLE_DEPTH],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_LANGUAGE],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_TRACK_NAME],
                      trackDescription[media.MediaDescriptionKey.MD_KEY_HDR_TYPE]
                    ]
                  )
                  }`)
                  let trackType = trackDescription[media.MediaDescriptionKey.MD_KEY_TRACK_TYPE]
                  if (trackType == 0) {
                    let index = parseInt(trackDescription[media.MediaDescriptionKey.MD_KEY_TRACK_INDEX] as string)
                    let language = trackDescription[media.MediaDescriptionKey.MD_KEY_LANGUAGE]
                    let name = trackDescription[media.MediaDescriptionKey.MD_KEY_TRACK_NAME]
                    audioTracks.push(index)
                    this.availableAudios.push({
                      index: index,
                      name: name ? name as string : "?",
                      language: language ? language as string : "?"
                    })
                  }

                })

                avPlayer.getSelectedTracks().then((selectedTracks) => {
                  for (let selectedTrack of selectedTracks) {
                    if (audioTracks.indexOf(selectedTrack) >= 0) {
                      this.selectedAudio = selectedTrack
                      break
                    }
                  }
                })
              })
          }
        })

        avPlayer.on('error', (err: BusinessError) => {
          console.error(`Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
          avPlayer.reset();
        });
        if (this.url.startsWith("file://media")) {
          console.error("opening file")
          fileIo.open(this.url)
            .then((file) => {
              console.error("playing video")
              avPlayer.url = `fd://${file.fd}`
            })
        } else if (this.url.startsWith("file://")) {
          console.error("hashing video")
          hash.hash(FileUtil.getFilePath(this.url), "sha256")
            .then((fileHash) => {
              console.error("opening file")
              fileIo.open(this.url)
                .then((file) => {
                  console.error("getting subtitles")
                  SubtitleLibraryDatabase.get(getContext(this), fileHash)
                    .then((subtitleUris) => {
                      avPlayer.url = `fd://${file.fd}`
                      subtitleUris.forEach(subtitleUrl => {
                        fileIo.open(subtitleUrl)
                          .then((subtitleFile) => {
                            hash.hash(subtitleFile.path, "sha256")
                              .then((subtitleHash) => {
                                fileIo.readText(subtitleFile.path)
                                  .then((readText) => {
                                    let compiledASS = compile(readText, void 0)
                                    let fileName = FileUtil.getFileName(subtitleUrl)
                                    this.subtitleHashes.push(subtitleHash)
                                    this.availableSubtitles.push({
                                      index: this.availableSubtitles.length,
                                      name: compiledASS.info.Title || fileName.substring(0, fileName.length - 4),
                                      language: "Ukn",
                                      compiledASS: compiledASS
                                    })
                                  })
                              })
                          })
                      })
                    })
                })
            })
        } else if (this.url.startsWith("dfs:")) {
          console.error("opening file")
          fileIo.open(this.url.substring(4))
            .then((file) => {
              console.error("playing video")
              avPlayer.url = `fd://${file.fd}`
            })
            .catch((error: BusinessError) => {
              console.error(`error occurs when accessing remote files: ${JSON.stringify(error)}`)
            })
        }
      })
  }
}

class VideoPlayerGestureModifier implements GestureModifier {
  private togglePause: () => void
  private showControls: () => void
  private startSpeedUp: () => void
  private endSpeedUp: () => void
  private brightnessAdjustStart: () => void
  private brightnessAdjustEnd: () => void
  private volumeAdjustStart: () => void
  private volumeAdjustEnd: () => void
  private brightnessUp: (value: number) => void
  private brightnessDown: (value: number) => void
  private volumeUp: (value: number) => void
  private volumeDown: (value: number) => void
  private brightnessOrVolume: boolean = true

  constructor(
    togglePause: () => void,
    showControls: () => void,
    startSpeedUp: () => void,
    endSpeedUp: () => void,
    brightnessAdjustStart: () => void,
    brightnessAdjustEnd: () => void,
    volumeAdjustStart: () => void,
    volumeAdjustEnd: () => void,
    brightnessUp: (value: number) => void,
    brightnessDown: (value: number) => void,
    volumeUp: (value: number) => void,
    volumeDown: (value: number) => void,
  ) {
    this.togglePause = togglePause
    this.showControls = showControls
    this.startSpeedUp = startSpeedUp
    this.endSpeedUp = endSpeedUp
    this.brightnessAdjustStart = brightnessAdjustStart
    this.brightnessAdjustEnd = brightnessAdjustEnd
    this.volumeAdjustStart = volumeAdjustStart
    this.volumeAdjustEnd = volumeAdjustEnd
    this.brightnessUp = brightnessUp
    this.brightnessDown = brightnessDown
    this.volumeUp = volumeUp
    this.volumeDown = volumeDown
  }

  private delta: number = 0

  applyGesture(event: UIGestureEvent): void {
    event.addGesture(
      new PanGestureHandler({ fingers: 1, direction: PanDirection.Vertical })
        .onActionStart((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          this.delta = 0
          let mainWindow: window.WindowProperties = VideoAbility.getWindow().getWindowProperties();
          let windowWidth: number = mainWindow.windowRect.width;
          let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
          let fingerInfo = event.fingerList[0]
          if (fingerInfo.globalX > windowWidthVp / 2) {
            this.brightnessOrVolume = false
            this.volumeAdjustStart()
          } else {
            this.brightnessOrVolume = true
            this.brightnessAdjustStart()
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          let realOffset = event.offsetY - this.delta
          this.delta = event.offsetY
          console.error('starting swipe gesture judgement')
          let mainWindow: window.WindowProperties = VideoAbility.getWindow().getWindowProperties();
          let windowWidth: number = mainWindow.windowRect.width;
          let windowHeight: number = mainWindow.windowRect.height;
          let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
          let windowHeightVp = windowHeight / display.getDefaultDisplaySync().densityPixels;
          let delta = windowHeightVp / 100
          console.error(`fingerInfo.globalX: windowHeightVp: ${windowWidthVp}, event offset: ${event.offsetY}`)
          if (!this.brightnessOrVolume) {
            // 右侧控制声音
            if (realOffset > 0) {
              this.volumeDown(Math.abs(realOffset) / delta)
            } else if (realOffset < 0) {
              this.volumeUp(Math.abs(realOffset) / delta)
            }
          } else {
            // 左侧控制亮度
            if (realOffset > 0) {
              this.brightnessDown(Math.abs(realOffset) / delta)
            } else if (realOffset < 0) {
              this.brightnessUp(Math.abs(realOffset) / delta)
            }
          }
        })
        .onActionEnd((event: GestureEvent) => {
          this.brightnessAdjustEnd()
          this.volumeAdjustEnd()
        })
    )
    event.addGesture(
      new TapGestureHandler({ count: 2, fingers: 1 })
        .onAction((event: GestureEvent) => {
          this.togglePause()
        })
    )
    event.addGesture(
      new TapGestureHandler({ count: 1, fingers: 1 })
        .onAction((event: GestureEvent) => {
          this.showControls()
        })
    )
    event.addGesture(
      new LongPressGestureHandler({ fingers: 1 })
        .onAction((event: GestureEvent) => {
          this.startSpeedUp()
        })
        .onActionEnd((event: GestureEvent) => {
          this.endSpeedUp()
        })
        .onActionCancel(() => {
          this.endSpeedUp()
        })
    )
  }
}

@Component
export struct TopBar_RightAlignedCircleSwitch {
  @Prop
  @Require
  icon: Resource
  @Link
  switchValue: boolean

  build() {
    Button({
      type: ButtonType.Circle
    }) {
      SymbolGlyph(this.icon)
        .fontSize(24)
        .fontColor([this.switchValue ? $r("app.color.icon_on_primary") : $r("app.color.icon_primary")])
        .symbolEffect(new BounceSymbolEffect(EffectScope.WHOLE, EffectDirection.DOWN), true)
    }
    .align(Alignment.Center)
    .margin({
      left: 12
    })
    .width(40)
    .height(40)
    .onClick(() => {
      this.switchValue = !this.switchValue
    })
    .backgroundColor(this.switchValue ? $r("app.color.brand") : $r("app.color.comp_background_tertiary"))
  }
}
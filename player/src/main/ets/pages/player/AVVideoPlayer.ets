import { BusinessError } from "@kit.BasicServicesKit";
import { media } from "@kit.MediaKit";
import { fileIo, hash, picker } from "@kit.CoreFileKit";
import { convertNumberToDurationString } from "../../util/TimeUtil";
import { common } from "@kit.AbilityKit";
import { curves, LengthMetrics, promptAction, SymbolGlyphModifier } from "@kit.ArkUI";
import { StringArray } from "../../entity/Arrays";
import { SubtitleLibraryDatabase } from "../../database/SubtitleLibraryDatabase";
import { FileUtil } from "@pura/harmony-utils";
import { showAlert } from "../../util/AlertUtil";
import { SubtitleEntity, Subtitles } from "../../entity/SubtitleEntity";
import { AudioEntity, Audios } from "../../entity/AudioEntity";
import { JSON } from "@kit.ArkTS";
import { compile } from "../../lib/ass_compiler";
import { AssSubtitleView } from "../subtitle/AssSubtitleView";

@Observed
export class VideoState {

  @Track
  paused: boolean = false

}

enum SurfaceFillingMode {

  Stretch, Fit, FourByThree, SixteenByNine

}

@Component
export struct AVVideoPlayer {

  @Prop
  @Require
  title: string
  @Prop
  @Require
  url: string

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
    }
  )

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

  build() {
    Stack() {
      Column() {
        Column() {
          this.topBar()
        }
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
      }
      .alignContent(Alignment.Center)
      .gestureModifier(this.videoPlayerGestureModifier)
      .width("100%")
      .height("100%")
      .zIndex(99) // 由于字幕也有分层，把 zIndex 设置高一点防止被字幕遮挡

      Stack() {
        Stack() {
          // TODO: 字幕层
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
          id: `avvideoplayer_${this.url}`,
          type: XComponentType.SURFACE,
          controller: this.xComponentController
        })
          .height(this.calculateHeightPercent(this.surfaceFillingMode))
          .width(this.calculateWidthPercent(this.surfaceFillingMode))
          .onAppear(() => {
            this.initAvPlayer()
          })
      }
      .backgroundColor(Color.Black)
      .alignContent(Alignment.Center)
      .width("100%")
      .height("100%")
      .zIndex(-100)  // 由于字幕也有分层，把 zIndex 设置小一点防止遮挡字幕
    }
    .width("100%")
    .height("100%")
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
          this.avPlayer?.release()
            .then(() => {
              (getContext(this) as common.UIAbilityContext).terminateSelf()
            })
        }
      )
      Text(this.title)
        .margin({
          left: 4,
          right: 4
        })
        .fontColor($r("app.color.font_primary"))
    }
    .padding({
      left: 16,
      right: 16,
      top: 12
    })
    .backgroundColor($r("app.color.comp_background_focus"))
    .alignItems(VerticalAlign.Center)
    .height("15%")
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
        value: this.currentPosition
      })
        .onChange((value, mode: SliderChangeMode) => {
          if (mode == SliderChangeMode.End || mode == SliderChangeMode.Click) {
            this.avPlayer?.seek(value)
          } else {
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
          this.avPlayer?.seek(Math.max(0, this.currentPosition - 10 * 1000))
        }
      )
      Button({
        type: ButtonType.Circle
      }) {
        if (this.videoState.paused) {
          SymbolGlyph($r("sys.symbol.play_fill"))
            .fontSize(24)
            .fontColor([$r("app.color.icon_primary")])
        } else {
          SymbolGlyph($r("sys.symbol.pause"))
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
          } else {
            this.avPlayer.pause()
            this.videoState.paused = true
          }
        }
      })
      .backgroundColor($r("app.color.comp_background_tertiary"))

      this.leftAlignedCircleButton(
        $r("sys.symbol.goforward_10"),
        () => {
          this.avPlayer?.seek(Math.min(this.max, this.currentPosition + 10 * 1000))
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
      .bindMenu(this.surfaceFillingModeMenus)
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
      .bindMenu(this.speedMenus)
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
      .bindMenu(this.audioMenus)
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
      .bindMenu(this.subtitleMenus)
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .padding({
      left: 16,
      right: 16,
      bottom: 12
    })
    .backgroundColor($r("app.color.comp_background_focus"))
    .alignItems(VerticalAlign.Center)
    .height("15%")
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

  @Builder
  subtitleMenus() {
    Menu() {
      MenuItemGroup() {
        MenuItem({
          content: $r("app.string.no_subtitle"),
          symbolEndIcon: this.selectedSubtitle == undefined ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.selectedSubtitle = undefined
          })
          .margin({
            top: 4,
            left: 4,
            right: 4
          })

        ForEach(this.availableSubtitles, (subtitle: SubtitleEntity, index: number) => {
          MenuItem({
            content: `${subtitle.name} (${subtitle.language})`,
            symbolEndIcon: this.selectedSubtitle == subtitle.index ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
          })
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
          content: $r("app.string.import")
        })
          .onClick(() => {
            this.showSubtitlePicker()/*
            promptAction.showToast({
              message: "由于字幕导入有问题，为了使用正常，暂时先屏蔽此功能"
            })*/
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
          MenuItem({
            content: `${audio.name} (${audio.language})`,
            symbolEndIcon: this.selectedAudio == audio.index ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
          })
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
        MenuItem({
          content: $r("app.string.surfaceFillingMode_fit"),
          symbolEndIcon: this.surfaceFillingMode == SurfaceFillingMode.Fit ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.surfaceFillingMode = SurfaceFillingMode.Fit
          })
          .margin({
            top: 4,
            left: 4,
            right: 4
          })
        MenuItem({
          content: $r("app.string.surfaceFillingMode_stretch"),
          symbolEndIcon: this.surfaceFillingMode == SurfaceFillingMode.Stretch ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.surfaceFillingMode = SurfaceFillingMode.Stretch
          })
          .margin({
            left: 4,
            right: 4
          })
        MenuItem({
          content: $r("app.string.surfaceFillingMode_4by3"),
          symbolEndIcon: this.surfaceFillingMode == SurfaceFillingMode.FourByThree ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.surfaceFillingMode = SurfaceFillingMode.FourByThree
          })
          .margin({
            left: 4,
            right: 4
          })
        MenuItem({
          content: $r("app.string.surfaceFillingMode_16by9"),
          symbolEndIcon: this.surfaceFillingMode == SurfaceFillingMode.SixteenByNine ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
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
        MenuItem({
          content: "0.50x",
          symbolEndIcon: this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_0_50_X ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_0_50_X)
          })
          .margin({
            top: 4,
            left: 4,
            right: 4
          })
        MenuItem({
          content: "0.75x",
          symbolEndIcon: this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_0_75_X ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_0_75_X)
          })
          .margin({
            left: 4,
            right: 4
          })
        MenuItem({
          content: "1.00x",
          symbolEndIcon: this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_1_00_X ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X)
          })
          .margin({
            left: 4,
            right: 4
          })
        MenuItem({
          content: "1.25x",
          symbolEndIcon: this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_1_25_X ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_25_X)
          })
          .margin({
            left: 4,
            right: 4
          })
        MenuItem({
          content: "1.50x",
          symbolEndIcon: this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_1_50_X ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_50_X)
          })
          .margin({
            left: 4,
            right: 4
          })
        MenuItem({
          content: "1.75x",
          symbolEndIcon: this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_1_75_X ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_75_X)
          })
          .margin({
            left: 4,
            right: 4
          })
        MenuItem({
          content: "2.00x",
          symbolEndIcon: this.currentSpeed == media.PlaybackSpeed.SPEED_FORWARD_2_00_X ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.updateSpeed(media.PlaybackSpeed.SPEED_FORWARD_2_00_X)
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

  onBackPress(): boolean | void {
    this.avPlayer?.release()
      .then(() => {
        (getContext(this) as common.UIAbilityContext).terminateSelf()
      })
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
              showAlert(this.getUIContext(), $r("app.string.duplicated_imports"), $r("app.string.duplicated_imports_desc"))
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
      if ((this.surfaceHeight / this.surfaceWidth) > (this.screenHeight / this.screenWidth)) {
        return `${((this.screenHeight / this.surfaceHeight * this.surfaceWidth) / this.screenWidth) * 100}%`
      } else {
        return "100%"
      }
    }
  }

  private calculateHeightPercent(surfaceFillingMode: SurfaceFillingMode): string {
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
      if ((this.surfaceHeight / this.surfaceWidth) > (this.screenHeight / this.screenWidth)) {
        return "100%"
      } else {
        return `${((this.screenWidth / this.surfaceWidth * this.surfaceHeight) / this.screenHeight) * 100}%`
      }
    }
  }

  private initAvPlayer() {
    this.findMetadata(this.url)
      .then((videoMetadata) => {
        this.videoMetadata = videoMetadata
        this.surfaceWidth = parseInt(this.videoMetadata.videoWidth!)
        this.surfaceHeight = parseInt(this.videoMetadata.videoHeight!)
      })
    media.createAVPlayer()
      .then((avPlayer: media.AVPlayer) => {
        this.avPlayer = avPlayer
        avPlayer.on("timeUpdate", (time: number) => {
          this.currentPosition = time
        })
        avPlayer.on('seekDone', (seekDoneTime: number) => {
          this.currentPosition = seekDoneTime
        });
        avPlayer.on("durationUpdate", (duration: number) => {
          this.max = duration
        })
        avPlayer.on("subtitleUpdate", (subtitle: media.SubtitleInfo) => {
          avPlayer.getTrackDescription()
            .then((trackDescriptions) => {
            })
        })
        avPlayer.on("stateChange", (state: string, reason: media.StateChangeReason) => {
          if (state == "paused") {
            console.error("paused")
            this.videoState.paused = true
          } else if (state == "playing") {
            console.error("playing")
            this.videoState.paused = false
          } else if (state == "idle") {
            console.error("idle")
            /*
            this.videoState.paused = true
            avPlayer.pause()*/
          } else if (state == "initialized") {
            console.error("initialized")
            avPlayer.surfaceId = this.xComponentController.getXComponentSurfaceId()
            avPlayer.prepare();
          } else if (state == "prepared") {
            console.error("prepared")
            avPlayer.play();

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
      })
  }

}

class VideoPlayerGestureModifier implements GestureModifier {

  supportDoubleTap: boolean = true

  private togglePause: () => void
  private showControls: () => void
  private startSpeedUp: () => void
  private endSpeedUp: () => void

  constructor(
    togglePause: () => void,
    showControls: () => void,
    startSpeedUp: () => void,
    endSpeedUp: () => void,
  ) {
    this.togglePause = togglePause
    this.showControls = showControls
    this.startSpeedUp = startSpeedUp
    this.endSpeedUp = endSpeedUp
  }

  applyGesture(event: UIGestureEvent): void {
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
      new LongPressGestureHandler({ fingers: 1})
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
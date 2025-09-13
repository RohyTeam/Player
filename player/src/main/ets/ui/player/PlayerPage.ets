import { AVSessionContext } from '../../context/AVSessionContext';
import { Sys } from '../../context/SystemContext';
import { AvPlayer, IjkPlayer } from '../../player/Player';
import { PlayerContext } from '../../player/PlayerContext';
import { PlayerController } from '../../player/PlayerController';
import { VideoSource, VideoSourceType } from '../../player/VideoSource';
import { Modifiers } from '../attributemodifier/Modifiers';
import { AvXComponent } from './AvXComponent';
import { IjkXComponent } from './IjkXComponent';
import { AssSubtitleView } from './subtitle/AssSubtitleView';
import { PgsSubtitleView } from './subtitle/PgsSubtitleView';
import { SrtSubtitleView } from './subtitle/SrtSubtitleView';
import { getScreenBrightness } from '../../utils/SystemSettings';
import { clamp } from '../../utils/MathUtils';
import { SubtitleInfo } from '../../player/subtitle/SubtitleInfo';
import { Pref } from '../../context/PreferenceContext';
import { BackgroundTaskContext } from '../../context/BackgroundTaskContext';
import { WindowContext } from '../../context/WindowContext';

@ComponentV2
export struct PlayerPage {
  @Param
  @Require
  videoSource: VideoSource
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Local
  windowContext: WindowContext = WindowContext.reach(this.getUIContext())

  aboutToAppear(): void {
    this.playerContext.playSpeed = 1
    this.playerContext.currentVolume = Sys.currentVolume
    this.playerContext.currentScreenBrightness = getScreenBrightness(this.getUIContext())

    // preferences
    this.playerContext.hardwareEncoding = Pref.hardwareDecoding

    // tracks
    //   audios
    this.playerContext.audios = []
    let audioIndex = 1
    for (let track of this.playerContext.videoSource!.metadata().metadata.tracks) {
      if (track.type == 1) {
        this.playerContext.audios.push({
          index: track.index,
          title: track.title ?? $r("app.string.internal_audio", `#${audioIndex}`),
          language: track.language,
          codec: track.codec
        })
        audioIndex += 1
      }
    }
    this.playerContext.selectedAudio = 0

    // subtitles
    this.playerContext.subtitles = []
    this.playerContext.subtitles.push(...this.playerContext.videoSource!.metadata().subtitles)
    this.playerContext.selectedSubtitle = undefined

    // chapters
    this.playerContext.chapters = []

    for (let chapter of this.playerContext.videoSource!.metadata().metadata.chapters) {
      this.playerContext.chapters.push({
        title: chapter.title ?? $r("app.string.untitled"),
        start: chapter.start,
        end: chapter.end
      })
    }

    // start player
    if (this.videoSource.type() == VideoSourceType.Photos) {
      this.playerContext.player = new AvPlayer()
    } else {
      this.playerContext.player = new IjkPlayer()
    }
    this.playerController.initPlayer(this.playerContext.player)
    this.playerContext.player!.onPrepared(() => {
      this.windowContext.window!.setWindowBrightness(clamp(this.playerContext.currentScreenBrightness /
        255, 0, 1)).then(() => {
      })
      this.playerController.play()
      if (!Sys.isPC()) {
        AVSessionContext.enableFunctions(this.getUIContext(), this.playerController)
        AVSessionContext.updateSession(this.getUIContext())
      }
    })
    this.playerContext.player.onPlay(() => {
      this.playerContext.paused = false
      if (!Sys.isPC()) {
        AVSessionContext.updateSession(this.getUIContext())
      }
    })
    this.playerContext.player.onPause(() => {
      this.playerContext.paused = true
      if (!Sys.isPC()) {
        AVSessionContext.updateSession(this.getUIContext())
      }
    })
    this.playerContext.player.onPositionChange((time) => {
      this.playerContext.currentPosition = time
      if (!this.playerContext.movingPosition) {
        this.playerContext.targetPosition = time
      }
      this.playerContext.subtitlePositionUpdater(time)
      if (!Sys.isPC()) {
        AVSessionContext.updateSession(this.getUIContext())
      }
    })
    this.playerContext.player.onSeekComplete((time) => {
      this.playerContext.currentPosition = time
      this.playerContext.subtitlePositionUpdater(time)
      if (!Sys.isPC()) {
        AVSessionContext.updateSession(this.getUIContext())
      }
    })
    this.playerContext.player.onCompleted(() => {
      if (this.playerContext.cycling) {
        this.playerController.pause()
        this.playerController.seek(0)
        this.playerController.play()
      } else {
        this.playerController.pause()
      }
    })
    BackgroundTaskContext.startBackgroundTask(this.getUIContext(), this.playerController)
  }

  aboutToDisappear(): void {
    this.windowContext.window!.setWindowBrightness(-1)
    this.playerController.release()
    this.playerContext.subtitles = []
    this.playerContext.selectedSubtitle = undefined
    this.playerContext.audios = []
    this.playerContext.selectedAudio = 0
    this.playerContext.chapters = []

    // 部分需要重置的首选项
    this.playerContext.mirrorFlipping = false
    this.playerContext.cycling = false
    this.playerContext.visualEffect_grayscale = 0
    this.playerContext.visualEffect_brightness = 0
    this.playerContext.visualEffect_saturate = 0
    this.playerContext.visualEffect_contrast = 0
    this.playerContext.visualEffect_invert = false

    BackgroundTaskContext.stopBackgroundTask(this.getUIContext())
  }

  build() {
    Stack() {
      Column() {
        if (this.playerContext.selectedSubtitle != undefined && this.playerContext.selectedSubtitle >= 0 &&
          this.playerContext.selectedSubtitle < this.playerContext.subtitles.length) {
          // 这样可以实现切换同类型的字幕，反正同一时间不可能出现多个字幕同时存在的
          ForEach(this.playerContext.subtitles, (subtitle: SubtitleInfo) => {
            if (this.playerContext.selectedSubtitle !== undefined
              && this.playerContext.subtitles[this.playerContext.selectedSubtitle] === subtitle) {
              // 不直接用 index 判断用来防止导入和删除外部字幕时出现问题
              if (this.playerContext.subtitles[this.playerContext.selectedSubtitle].type == 'ass') {
                AssSubtitleView()
              } else if (this.playerContext.subtitles[this.playerContext.selectedSubtitle].type == 'pgs') {
                PgsSubtitleView()
              } else if (this.playerContext.subtitles[this.playerContext.selectedSubtitle].type == 'srt') {
                SrtSubtitleView()
              }
            }
          })
        }
      }
      .attributeModifier(Modifiers.surfaceFilling(this.videoSource.metadata().metadata,
        this.playerContext.surfaceFillingMode))
      .zIndex(2)

      Column() {
        Column() {
          Column() {
            Column() {
              Column() {
                Column() {
                  if (this.videoSource.type() == VideoSourceType.Photos) {
                    AvXComponent({
                      videoSource: this.videoSource,
                      player: this.playerContext.player as AvPlayer
                    })
                  } else {
                    IjkXComponent({
                      videoSource: this.videoSource,
                      player: this.playerContext.player as IjkPlayer
                    })
                  }
                }
                .width("100%")
                .height("100%")
                .invert(this.playerContext.visualEffect_invert ? 1 : 0)
              }
              .width("100%")
              .height("100%")
              .contrast((this.playerContext.visualEffect_contrast + 100) / 100)
            }
            .width("100%")
            .height("100%")
            .saturate((this.playerContext.visualEffect_saturate + 100) / 100)
          }
          .width("100%")
          .height("100%")
          .brightness((this.playerContext.visualEffect_brightness + 100) / 100)
        }
        .width("100%")
        .height("100%")
        .grayscale(this.playerContext.visualEffect_grayscale / 100)
      }
      .id('player_view')
      .onAreaChange((_, newArea) => {
        this.playerContext.playerWidthVp = Number(newArea.width)
        this.playerContext.playerHeightVp = Number(newArea.height)
        this.playerContext.playerWidthPx = vp2px(this.playerContext.playerWidthVp)
        this.playerContext.playerHeightPx = vp2px(this.playerContext.playerHeightVp)
      })
      .attributeModifier(Modifiers.surfaceFilling(this.videoSource.metadata().metadata,
        this.playerContext.surfaceFillingMode))
      .rotate({
        centerX: "50%",
        centerY: "50%",
        x: 0,
        y: 1,
        z: 0,
        angle: this.playerContext.mirrorFlipping ? 180 : 0
      })
      .zIndex(1)
    }
    .rotate({
      centerX: "50%",
      centerY: "50%",
      x: 0,
      y: 0,
      z: 1,
      angle: this.playerContext.visualEffect_rotation
    })
    .scale({
      x: this.playerContext.visualEffect_rotation === 90 || this.playerContext.visualEffect_rotation === 270 ? this.windowContext.heightVp / this.windowContext.widthVp : 1,
      y: this.playerContext.visualEffect_rotation === 90 || this.playerContext.visualEffect_rotation === 270 ? this.windowContext.heightVp / this.windowContext.widthVp : 1
    })
    .width("100%")
    .height("100%")
  }
}
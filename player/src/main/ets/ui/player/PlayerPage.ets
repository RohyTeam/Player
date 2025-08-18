import { RohyAssSubtitleRenderer } from 'librohy_subtitle.so';
import { AVSessionContext } from '../../context/AVSessionContext';
import { Sys } from '../../context/SystemContext';
import { AvPlayer, IjkPlayer } from '../../player/Player';
import { PlayerContext } from '../../player/PlayerContext';
import { PlayerController } from '../../player/PlayerController';
import { VideoSource, VideoSourceType } from '../../player/VideoSource';
import { AbilityStorage } from '../../storage/AbilityStorage';
import { Modifiers } from '../attributemodifier/Modifiers';
import { AvXComponent } from './AvXComponent';
import { IjkXComponent } from './IjkXComponent';
import { AssSubtitleView } from './subtitle/AssSubtitleView';
import { PgsSubtitleView } from './subtitle/PgsSubtitleView';
import { SrtSubtitleView } from './subtitle/SrtSubtitleView';

@ComponentV2
export struct PlayerPage {
  @Param
  @Require
  videoSource: VideoSource
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  aboutToAppear(): void {
    this.playerContext.subtitles = []
    this.playerContext.subtitles.push(...this.playerContext.videoSource!.metadata().subtitles)
    this.playerContext.selectedSubtitle = undefined
    this.playerContext.audios = []
    let audioIndex = 1
    for (let track of this.playerContext.videoSource!.metadata().metadata.tracks) {
      if (track.type == 1) {
        this.playerContext.audios.push({
          index: track.index,
          title: track.title ?? $r("app.string.internal_audio", `#${audioIndex}`),
          language: track.language
        })
        audioIndex += 1
      }
    }
    this.playerContext.selectedAudio = 0
    if (this.videoSource.type() == VideoSourceType.Photos) {
      this.playerContext.player = new AvPlayer()
    } else {
      this.playerContext.player = new IjkPlayer()
    }
    this.playerController.initPlayer(this.playerContext.player)
    this.playerContext.player!.onPrepared(() => {
      this.playerController.play()
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
      this.playerController.pause()
    })
  }

  aboutToDisappear(): void {
    this.playerController.release()
    this.playerContext.subtitles = []
    this.playerContext.selectedSubtitle = undefined
    this.playerContext.audios = []
    this.playerContext.selectedAudio = 0
  }

  build() {
    Stack() {
      Column() {
        if (this.playerContext.selectedSubtitle != undefined && this.playerContext.selectedSubtitle >= 0 && this.playerContext.selectedSubtitle < this.playerContext.subtitles.length) {
          if (this.playerContext.subtitles[this.playerContext.selectedSubtitle].type == 'ass') {
            AssSubtitleView()
          } else if (this.playerContext.subtitles[this.playerContext.selectedSubtitle].type == 'pgs') {
            PgsSubtitleView()
          } else if (this.playerContext.subtitles[this.playerContext.selectedSubtitle].type == 'srt') {
            SrtSubtitleView()
          }
        }
      }
      .attributeModifier(Modifiers.surfaceFilling(this.videoSource.metadata().metadata, this.playerContext.surfaceFillingMode))
      .zIndex(2)
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
      .id('player_view')
      .onAreaChange((_, newArea) => {
        this.playerContext.playerWidthVp = Number(newArea.width)
        this.playerContext.playerHeightVp = Number(newArea.height)
        this.playerContext.playerWidthPx = vp2px(this.playerContext.playerWidthVp)
        this.playerContext.playerHeightPx = vp2px(this.playerContext.playerHeightVp)
      })
      .attributeModifier(Modifiers.surfaceFilling(this.videoSource.metadata().metadata, this.playerContext.surfaceFillingMode))
      .zIndex(1)
    }
    .width("100%")
    .height("100%")
  }
}
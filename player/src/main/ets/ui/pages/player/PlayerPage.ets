import { AvPlayer, IjkPlayer } from "../../../player/Player";
import { PlayerContext } from "../../../player/PlayerContext";
import { PlayerController } from "../../../player/PlayerController";
import { SurfaceFillingMode } from "../../../player/SurfaceFillingMode";
import { VideoSource, VideoSourceType } from "../../../player/VideoSource";
import { AbilityStorage } from "../../../storage/AbilityStorage";
import { Modifiers } from "../../attributemodifier/Modifiers";
import { AvXComponent } from "./AvXComponent";
import { IjkXComponent } from "./IjkXComponent";

@ComponentV2
export struct PlayerPage {

  @Param
  @Require
  videoSource: VideoSource

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()

  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  aboutToAppear(): void {
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
    })
    this.playerContext.player.onPause(() => {
      this.playerContext.paused = true
    })
    this.playerContext.player.onPositionChange((time) => {
      this.playerContext.currentDuration = time
    })
    this.playerContext.player.onSeekComplete((time) => {
      this.playerContext.currentDuration = time
    })
  }

  build() {
    Stack() {
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
      .attributeModifier(Modifiers.surfaceFilling(this.videoSource.metadata(), this.playerContext.surfaceFillingMode))
    }
    .width("100%")
    .height("100%")
  }

}
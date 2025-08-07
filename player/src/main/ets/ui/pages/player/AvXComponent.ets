import { AvPlayer } from "../../../player/Player"
import { PlayerContext } from "../../../player/PlayerContext"
import { VideoSource } from "../../../player/VideoSource"
import { AbilityStorage } from "../../../storage/AbilityStorage"
import { ability } from "../../../utils/AbilityUtils"

@ComponentV2
export struct AvXComponent {

  @Param
  @Require
  videoSource: VideoSource
  @Param
  @Require
  player: AvPlayer
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  private xComponentController: XComponentController = new XComponentController()

  build() {
    XComponent({
      id: this.videoSource.identity(),
      type: XComponentType.SURFACE,
      controller: this.xComponentController
    })
      .onAppear(() => {
        this.player.prepare(ability(this.getUIContext()).context, undefined, this.xComponentController, this.videoSource)
      })
      .width("100%")
      .height("100%")
  }

}
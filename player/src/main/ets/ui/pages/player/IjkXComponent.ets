import { IjkPlayer } from "../../../player/Player"
import { PlayerContext } from "../../../player/PlayerContext"
import { VideoSource } from "../../../player/VideoSource"
import { AbilityStorage } from "../../../storage/AbilityStorage"
import { ability } from "../../../utils/AbilityUtils"

@ComponentV2
export struct IjkXComponent {

  @Param
  @Require
  videoSource: VideoSource
  @Param
  @Require
  player: IjkPlayer
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  build() {
    XComponent({
      id: this.videoSource.identity(),
      type: XComponentType.SURFACE,
      libraryname: 'ijkplayer_napi'
    })
      .onLoad((context) => {
        this.player.prepare(ability(this.getUIContext()).context, context!, this.videoSource.identity(), this.videoSource)
      })
      .width("100%")
      .height("100%")
  }

}
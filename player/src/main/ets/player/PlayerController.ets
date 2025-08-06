import { Player } from "./Player";
import { VideoMetadata } from "./VideoMetadata";

@ObservedV2
export class PlayerController {

  private player: Player | undefined = undefined
  @Trace
  metadata: VideoMetadata | undefined = undefined

  initPlayer(player: Player) {
    this.player = player
  }

}
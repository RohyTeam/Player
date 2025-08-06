import { PlayerController } from "../../../player/PlayerController"
import { convertNumberToDurationString } from "../../../utils/NumberUtils"

@ComponentV2
export struct PlayerProgressBar {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()

  build() {
    Row() {
      Text(`${convertNumberToDurationString(this.playerController.metadata?.currentDuration)}`)
        .margin({
          left: 16,
          right: 4
        })
        .fontColor($r("sys.color.font_secondary"))
      Slider({
        min: 0,
        max: this.playerController.metadata?.maxDuration,
        step: 1,
        value: this.playerController.metadata?.currentDuration
      })
        .enabled(this.playerController.metadata != null)
        .onChange((value, mode: SliderChangeMode) => {
        })
        .layoutWeight(1)
      Text(`${convertNumberToDurationString(this.playerController.metadata?.maxDuration)}`)
        .margin({
          left: 4,
          right: 16
        })
        .fontColor($r("sys.color.font_secondary"))
    }
    .width("100%")
  }


}
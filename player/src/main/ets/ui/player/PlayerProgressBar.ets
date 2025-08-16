import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { AbilityStorage } from '../../storage/AbilityStorage'
import { convertNumberToDurationString } from '../../utils/NumberUtils'

@ComponentV2
export struct PlayerProgressBar {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  build() {
    Row() {
      if (this.playerContext.video) {
        this.videoProgressBar()
      } else {
        this.nonVideoProgressBar()
      }
    }
    .width("100%")
  }

  @Builder
  private videoProgressBar() {
    Text(`${convertNumberToDurationString(this.playerContext.currentPosition)}`)
      .margin({
        left: 16,
        right: 4
      })
      .fontColor($r("sys.color.font_secondary"))
    Slider({
      min: 0,
      max: this.playerContext.maxDuration,
      step: 1,
      value: this.playerContext.currentPosition
    })
      .onChange((value, mode: SliderChangeMode) => {
        // todo
        if (mode == SliderChangeMode.End || mode == SliderChangeMode.Click) {
          this.playerController.seek(value)
        }
      })
      .layoutWeight(1)
    Text(`${convertNumberToDurationString(this.playerContext.maxDuration)}`)
      .margin({
        left: 4,
        right: 16
      })
      .fontColor($r("sys.color.font_secondary"))
  }

  @Builder
  private nonVideoProgressBar() {
    Text(`**:**`)
      .margin({
        left: 16,
        right: 4
      })
      .fontColor($r("sys.color.font_secondary"))
    Slider({
      min: 0,
      max: 0,
      step: 1,
      value: 0
    })
      .enabled(false)
      .layoutWeight(1)
    Text(`**:**`)
      .margin({
        left: 4,
        right: 16
      })
      .fontColor($r("sys.color.font_secondary"))
  }
}
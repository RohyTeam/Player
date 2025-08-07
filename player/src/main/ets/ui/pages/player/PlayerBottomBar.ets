import { Sys } from "../../../context/SystemContext"
import { PlayerContext } from "../../../player/PlayerContext"
import { PlayerController } from "../../../player/PlayerController"
import { AbilityStorage } from "../../../storage/AbilityStorage"
import { Modifiers } from "../../attributemodifier/Modifiers"
import { CircleIconButton } from "../../button/CircleIconButton"
import { PlayerProgressBar } from "./PlayerProgressBar"

@ComponentV2
export struct PlayerBottomBar {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Consumer("showSidebar")
  showSidebar: boolean = false
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  build() {
    Column() {
      PlayerProgressBar()
      Row() {
        CircleIconButton({
          icon: $r("sys.symbol.gobackward_15"),
          buttonMargin: {
            left: 16,
            bottom: 12
          }
        })
        this.playAndPauseButton()
        CircleIconButton({
          icon: $r("sys.symbol.goforward_15"),
          buttonMargin: {
            left: 12,
            bottom: 12
          }
        })
        Blank()
          .layoutWeight(1)
        if (Sys.isPC()) {
          CircleIconButton({
            icon: $r("sys.symbol.open_sidebar"),
            buttonMargin: {
              right: 16,
              bottom: 12
            },
            clickCallback: () => {
              this.showSidebar = true
            }
          })
        }
      }
      .width("100%")
    }
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
    .width("100%")
    .attributeModifier(Modifiers.backgroundBlur())
  }

  @Builder
  private playAndPauseButton() {
    if (!this.playerContext.video || this.playerContext.paused) {
      CircleIconButton({
        icon: $r("sys.symbol.play_fill"),
        buttonMargin: {
          left: 12,
          bottom: 12
        },
        clickCallback: () => {
          if (!this.playerContext.video)
            return
          this.playerController.play()
        }
      })
    } else {
      CircleIconButton({
        icon: $r("sys.symbol.pause"),
        buttonMargin: {
          left: 12,
          bottom: 12
        },
        clickCallback: () => {
          if (!this.playerContext.video)
            return
          this.playerController.pause()
        }
      })
    }
  }

}
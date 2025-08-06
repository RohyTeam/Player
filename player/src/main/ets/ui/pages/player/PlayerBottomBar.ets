import { Sys } from "../../../context/SystemContext"
import { PlayerController } from "../../../player/PlayerController"
import { CircleIconButton } from "../../button/CircleIconButton"
import { PlayerProgressBar } from "./PlayerProgressBar"

@ComponentV2
export struct PlayerBottomBar {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Consumer("showSidebar")
  showSidebar: boolean = false

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
        CircleIconButton({
          icon: $r("sys.symbol.play"),
          buttonMargin: {
            left: 12,
            bottom: 12
          }
        })
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
    .backgroundColor($r("app.color.rohy_card"))
  }

}
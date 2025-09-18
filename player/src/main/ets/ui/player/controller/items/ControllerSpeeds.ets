import { PlayerContext } from "../../../../player/PlayerContext"
import { buildMenuGroup, menuGroups, RohyMenu, RohyMenuItem } from "../../../component/menu/RohyMenu"
import { LengthMetrics, SymbolGlyphModifier } from "@kit.ArkUI"
import { PlayerController } from "../../../../player/PlayerController"
import { CircleIconButton } from "../../../button/CircleIconButton"
import { ControllerMenuButton } from "../ControllerItems"

@ComponentV2
struct ControllerSpeeds {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  build() {
    Menu() {
      ForEach([0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0], (speed: number) => {
        if (this.playerContext.playSpeed == speed) {
          MenuItem({
            content: this.speedToText(speed),
            symbolEndIcon: new SymbolGlyphModifier($r("sys.symbol.checkmark")).fontSize(24)
          })
        } else {
          MenuItem({
            content: this.speedToText(speed),
          })
            .onClick(() => {
              this.playerController.setSpeed(speed)
            })
        }
      })
    }
    .menuItemDivider({
      color: $r("sys.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
      startMargin: LengthMetrics.vp(4),
      endMargin: LengthMetrics.vp(4)
    })
  }

  private speedToText(speed: number): ResourceStr {
    switch (speed) {
      case 0.25:
        return $r("app.string.speed_0_25")
      case 0.5:
        return $r("app.string.speed_0_50")
      case 0.75:
        return $r("app.string.speed_0_75")
      case 1.25:
        return $r("app.string.speed_1_25")
      case 1.5:
        return $r("app.string.speed_1_50")
      case 1.75:
        return $r("app.string.speed_1_75")
      case 2:
        return $r("app.string.speed_2_00")
      default:
        return $r("app.string.speed_1_00")
    }
  }

}

@Builder
function speedsMenu() {
  ControllerSpeeds()
}

@Builder
export function speedsMenuItem() {
  MenuItem({
    symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.video_speed")),
    content: $r("app.string.speed"),
    builder: speedsMenu
  })
}

@Builder
export function speedsButton(margin: Margin) {
  ControllerMenuButton({
    icon: $r("sys.symbol.video_speed"),
    buttonMargin: margin
  }) {
    speedsMenu()
  }
}
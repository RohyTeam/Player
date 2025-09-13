import { PlayerContext } from "../../../../player/PlayerContext"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { PlayerController } from "../../../../player/PlayerController"
import { ControllerSwitchButton } from "../ControllerItems"

@ComponentV2
struct ControllerMirrorFlipMenuItem {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  build() {
    MenuItem({
      symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.trapezoid_and_line_vertical")),
      content: $r("app.string.mirror_flip"),
      symbolEndIcon: this.playerContext.mirrorFlipping ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined,
    })
      .onClick(() => {
        this.playerContext.mirrorFlipping = !this.playerContext.mirrorFlipping
      })
  }

}

@Builder
export function mirrorFlipMenuItem() {
  MenuItem() {
    ControllerMirrorFlipMenuItem()
  }
}

@Builder
export function mirrorFlipButton(margin: Margin) {
  ControllerSwitchButton({
    icon: $r("sys.symbol.trapezoid_and_line_vertical"),
    buttonMargin: margin,
    switch: (value, context) => {
      context.mirrorFlipping = value
      return value
    }
  })
}
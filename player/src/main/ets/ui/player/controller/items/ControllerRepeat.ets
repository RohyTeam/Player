import { PlayerContext } from "../../../../player/PlayerContext"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { PlayerController } from "../../../../player/PlayerController"
import { ControllerSwitchButton } from "../ControllerItems"

@ComponentV2
struct ControllerRepeatMenuItem {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  build() {
    MenuItem({
      symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.repeat")),
      content: $r("app.string.loop_playing"),
      symbolEndIcon: this.playerContext.cycling ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined,
    })
      .onClick(() => {
        this.playerContext.cycling = !this.playerContext.cycling
      })
  }

}

@Builder
export function repeatMenuItem() {
  MenuItem() {
    ControllerRepeatMenuItem()
  }
}

@Builder
export function repeatButton(margin: Margin) {
  ControllerSwitchButton({
    icon: $r("sys.symbol.repeat"),
    buttonMargin: margin,
    switch: (value, context) => {
      context.cycling = value
      return value
    }
  })
}
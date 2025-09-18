import { PlayerContext } from "../../../../player/PlayerContext"
import { buildMenuGroup, menuGroups, RohyMenu, RohyMenuItem } from "../../../component/menu/RohyMenu"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { PlayerController } from "../../../../player/PlayerController"
import { CircleIconButton } from "../../../button/CircleIconButton"
import { ControllerMenuButton } from "../ControllerItems"
import { SURFACE_FILLING_MODES, SURFACE_FILLING_MODE_NAMES } from "../../../../player/SurfaceFillingMode"

@ComponentV2
struct ControllerSurfaceFillingModes {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  build() {
    RohyMenu({
      groups: menuGroups(() => [
        buildMenuGroup(() => {
          let items: RohyMenuItem[] = []
          SURFACE_FILLING_MODES.forEach((surfaceFillingMode, index) => {
            items.push({
              options: {
                content: SURFACE_FILLING_MODE_NAMES[surfaceFillingMode],
                symbolEndIcon: this.playerContext.surfaceFillingMode === surfaceFillingMode ?
                  new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
              },
              action: () => {
                if (this.playerContext.surfaceFillingMode == index) {
                  return
                }

                this.playerController.setFillingMode(surfaceFillingMode)
              }
            })
          })
          return items
        })
      ])
    })
  }

}

@Builder
function surfaceFillingModesMenu() {
  ControllerSurfaceFillingModes()
}

@Builder
export function surfaceFillingModesMenuItem() {
  MenuItem({
    symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.resolution_video")),
    content: $r("app.string.surface_filling_mode"),
    builder: surfaceFillingModesMenu
  })
}

@Builder
export function surfaceFillingModesButton(margin: Margin) {
  ControllerMenuButton({
    icon: $r("sys.symbol.resolution_video"),
    buttonMargin: margin
  }) {
    surfaceFillingModesMenu()
  }
}
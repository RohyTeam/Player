import { PlayerContext } from "../../../../player/PlayerContext"
import { buildMenuGroup, menuGroups, RohyMenu, RohyMenuItem } from "../../../component/menu/RohyMenu"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { PlayerController } from "../../../../player/PlayerController"
import { CircleIconButton } from "../../../button/CircleIconButton"
import { ControllerClickButton, ControllerMenuButton } from "../ControllerItems"
import { ControlsContext } from "../../PlayerBottomBar"

@ComponentV2
struct ControllerChapterListMenuItem {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  @Consumer("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()

  build() {
    MenuItem({
      symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.bookmark")),
      content: $r("app.string.chapter_list")
    })
      .onClick(() => {
        this.controlsContext.showChapterList = true
      })
  }

}

@ComponentV2
struct ControllerChapterListButton {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  @Consumer("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()

  @Param
  @Require
  buttonMargin: Margin = {}

  build() {
    ControllerClickButton({
      icon: $r("sys.symbol.bookmark"),
      buttonMargin: this.buttonMargin,
      click: () => {
        this.controlsContext.showChapterList = true
      }
    })
  }

}

@Builder
export function chapterListMenuItem() {
  MenuItem() {
    ControllerChapterListMenuItem()
  }
}

@Builder
export function chapterListButton(margin: Margin) {
  ControllerChapterListButton({
    buttonMargin: margin
  })
}
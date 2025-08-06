import { SymbolGlyphModifier } from "@kit.ArkUI"
import { Modifiers } from "../../attributemodifier/Modifiers"

@ComponentV2
export struct PlaylistSideBar {

  @Consumer("showSidebar")
  showSidebar: boolean = false

  build() {
    Navigation() {
      // todo
    }
    .width("100%")
    .height("100%")
    .attributeModifier(Modifiers.backgroundBlur())
    .navDestination(this.SidebarPager)
    .hideBackButton(true)
    .hideToolBar(true)
    .menus([
      {
        value: "close",
        symbolIcon: new SymbolGlyphModifier($r("sys.symbol.xmark")),
        action: () => {
          this.showSidebar = false
        }
      }
    ])
    .title($r("app.string.playlist"))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }

  @Builder
  SidebarPager(name: string) {

  }

}
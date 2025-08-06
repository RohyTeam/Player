import { DropPage } from "./DropPage"
import { PCControlPanel } from "../player/PCControlPanel"
import { curves, SymbolGlyphModifier } from "@kit.ArkUI"
import { Modifiers } from "../../attributemodifier/Modifiers"
import { PlaylistSideBar } from "./PlaylistSideBar"

@ComponentV2
export struct PCIndex {

  @Local
  showPlayList: boolean = false
  @Provider("showSidebar")
  showSidebar: boolean = false

  build() {
    Column() {
      SideBarContainer(SideBarContainerType.Overlay) {
        // sidebar
        PlaylistSideBar()
          .borderRadius(16)
          .margin({
            top: 16,
            right: 16,
            bottom: 16
          })
          .visibility(this.showSidebar ? Visibility.Visible : Visibility.Hidden)
          .animation({
            curve: curves.springMotion(),
            duration: 200
          })
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.move(TransitionEdge.END).combine(TransitionEffect.OPACITY),
              TransitionEffect.move(TransitionEdge.END).combine(TransitionEffect.OPACITY)
            )
          )

        // content
        Stack() {
          DropPage()
            .zIndex(1)
          PCControlPanel()
            .zIndex(2)
          if (this.showSidebar) {
            // an overlay
            Column()
              .onClick(() => {
                this.showSidebar = false
              })
              .width("100%")
              .height("100%")
              .zIndex(3)
          }
        }
        .width("100%")
        .height("100%")
      }
      .width("100%")
      .height("100%")
      .divider({
        strokeWidth: 0
      })
      .autoHide(true)
      .showControlButton(false)
      .showSideBar(true)
      .sideBarWidth("33%")
      .sideBarPosition(SideBarPosition.End)
      .backgroundColor(Color.Transparent)
    }
    .backgroundColor(Color.Transparent)
    .width("100%")
    .height("100%")
  }

}
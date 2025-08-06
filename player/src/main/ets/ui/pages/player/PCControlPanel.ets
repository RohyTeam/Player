import { Sys } from "../../../context/SystemContext"
import { PlayerBottomBar } from "./PlayerBottomBar"
import { curves } from "@kit.ArkUI"

@ComponentV2
export struct PCControlPanel {

  @Local
  lastMovingMouse: number = 0
  @Consumer("showSidebar")
  showSidebar: boolean = false

  build() {
    Column() {
      Blank()
        .layoutWeight(1)
      PlayerBottomBar()
        .visibility((Sys.time - this.lastMovingMouse < 3 * 1000) || this.showSidebar ? Visibility.Visible : Visibility.Hidden)
        .animation({
          curve: curves.springMotion(),
          duration: 200
        })
        .transition(
          TransitionEffect.asymmetric(
            TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY),
            TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY)
          )
        )
    }
    .onMouse(() => {
      animateTo({}, () => {
        this.lastMovingMouse = Date.now()
      })
    })
    .width("100%")
    .height("100%")
  }

}
import { PlayerController } from "../../player/PlayerController";
import { BottomBarContext } from "../player/PlayerBottomBar";

export class HandGestureModifier implements GestureModifier {

  private controller: PlayerController
  private bottomBarContext?: BottomBarContext

  constructor(controller: PlayerController, bottomBarContext?: BottomBarContext) {
    this.controller = controller
    this.bottomBarContext = bottomBarContext
  }

  private brightnessOrVolume: boolean = true
  private fingerMovingDelta: number = 0

  applyGesture(event: UIGestureEvent): void {
    // todo: 滑动屏幕跳转亮度和音量
    event.addGesture(
      new PanGestureHandler({ fingers: 1, direction: PanDirection.Vertical })
        .onActionStart((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          let windowContext = this.controller.getWindowContext()
          if (!windowContext)
            return
          this.fingerMovingDelta = 0
          let fingerInfo = event.fingerList[0]
          if (fingerInfo.globalX > windowContext.widthVp / 2) {
            this.brightnessOrVolume = false
            this.controller.startAdjustingVolume()
          } else {
            this.brightnessOrVolume = true
            this.controller.startAdjustingScreenBrightness()
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          let windowContext = this.controller.getWindowContext()
          if (!windowContext)
            return
          let realOffset = event.offsetY - this.fingerMovingDelta
          this.fingerMovingDelta = event.offsetY
          let delta = windowContext.heightVp / 100
          if (!this.brightnessOrVolume) {
            // 右侧控制声音
            if (realOffset > 0) {
              this.controller.decreaseVolume(Math.abs(realOffset) / delta)
            } else if (realOffset < 0) {
              this.controller.increaseVolume(Math.abs(realOffset) / delta)
            }
          } else {
            // 左侧控制亮度
            if (realOffset > 0) {
              this.controller.decreaseScreenBrightness(Math.abs(realOffset) / delta)
            } else if (realOffset < 0) {
              this.controller.increaseScreenBrightness(Math.abs(realOffset) / delta)
            }
          }
        })
        .onActionEnd((event: GestureEvent) => {
          this.controller.stopAdjustingScreenBrightness()
          this.controller.stopAdjustingVolume()
        })
    )
    event.addGesture(
      new TapGestureHandler({ count: 2, fingers: 1 })
        .onAction((event: GestureEvent) => {
          this.controller.playOrPause()
        })
    )
    event.addGesture(
      new TapGestureHandler({ count: 1, fingers: 1 })
        .onAction((event: GestureEvent) => {
          if (this.bottomBarContext)
            this.bottomBarContext.shown = !this.bottomBarContext.shown
        })
    )
    event.addGesture(
      new LongPressGestureHandler({ fingers: 1 })
        .onAction((event: GestureEvent) => {
          this.controller.startLongPressSpeeding()
        })
        .onActionEnd((event: GestureEvent) => {
          this.controller.stopLongPressSpeeding()
        })
        .onActionCancel(() => {
          this.controller.stopLongPressSpeeding()
        })
    )
  }

}
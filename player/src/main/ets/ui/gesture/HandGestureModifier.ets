import { Pref } from '../../context/PreferenceContext';
import { Sys } from '../../context/SystemContext';
import { PlayerContext } from '../../player/PlayerContext';
import { PlayerController } from '../../player/PlayerController';
import { ControlsContext } from '../player/PlayerBottomBar';

export class HandGestureModifier implements GestureModifier {
  private controller: PlayerController
  private playerContext: PlayerContext
  private controlsContext?: ControlsContext

  constructor(controller: PlayerController, playerContext: PlayerContext, controlsContext?: ControlsContext) {
    this.controller = controller
    this.playerContext = playerContext
    this.controlsContext = controlsContext
  }

  private brightnessOrVolume: boolean = true
  private fingerMovingDelta: number = 0

  applyGesture(event: UIGestureEvent): void {
    event.addGesture(
      new PanGestureHandler({ fingers: 1, direction: PanDirection.Vertical })
        .onActionStart((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          let windowContext = this.controller.getWindowContext()
          if (!windowContext) {
            return
          }
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
          if (!windowContext) {
            return
          }
          let realOffset = event.offsetY - this.fingerMovingDelta
          this.fingerMovingDelta = event.offsetY
          if (!this.brightnessOrVolume) {
            let value = Math.abs(realOffset) / windowContext.heightVp * Sys.maxVolume
            // 右侧控制声音
            if (realOffset > 0) {
              this.controller.decreaseVolume(value)
            } else if (realOffset < 0) {
              this.controller.increaseVolume(value)
            }
          } else {
            let value = Math.abs(realOffset) / windowContext.heightVp * 255
            // 左侧控制亮度
            if (realOffset > 0) {
              this.controller.decreaseScreenBrightness(value)
            } else if (realOffset < 0) {
              this.controller.increaseScreenBrightness(value)
            }
          }
        })
        .onActionEnd((event: GestureEvent) => {
          this.controller.stopAdjustingScreenBrightness()
          this.controller.stopAdjustingVolume()
        })
    )
    event.addGesture(
      new PanGestureHandler({ fingers: 1, direction: PanDirection.Horizontal })
        .onActionStart((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          let windowContext = this.controller.getWindowContext()
          if (!windowContext) {
            return
          }
          this.fingerMovingDelta = 0
          this.controller.startMovingPosition()
        })
        .onActionUpdate((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          let windowContext = this.controller.getWindowContext()
          if (!windowContext) {
            return
          }
          let realOffset = event.offsetX - this.fingerMovingDelta
          this.fingerMovingDelta = event.offsetX
          let value = realOffset / windowContext.heightVp / 4 * this.playerContext.maxDuration
          this.playerContext.targetPosition += value
        })
        .onActionEnd((event: GestureEvent) => {
          this.controller.seekTarget()
          this.controller.stopMovingPosition()
        })
    )
    event.addGesture(
      new TapGestureHandler({ count: 2, fingers: 1 })
        .onAction((event: GestureEvent) => {
          if (Pref.screenForwardAndBackward) {
            let windowContext = this.controller.getWindowContext()
            if (!windowContext) {
              return
            }
            let fingerInfo = event.fingerList[0]
            if (fingerInfo.globalX < windowContext.widthVp / 3) { // 左三分之一屏
              this.controller.goBackward(15 * 1000)
            } else if (fingerInfo.globalX > windowContext.widthVp / 3 * 2) { // 右三分之一屏
              this.controller.goForward(15 * 1000)
            } else { // 中三分之一屏
              this.controller.playOrPause()
            }
          } else {
            this.controller.playOrPause()
          }
        })
    )
    event.addGesture(
      new TapGestureHandler({ count: 1, fingers: 1 })
        .onAction((event: GestureEvent) => {
          if (!this.controlsContext) {
            return
          }
          this.controlsContext.showTopBarAndBottomBar = !this.controlsContext.showTopBarAndBottomBar
          if (!this.controlsContext.showTopBarAndBottomBar) {
            this.controlsContext.showChapterList = false
          }
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
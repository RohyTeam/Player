import { DialogHelper } from "@pura/harmony-dialog"
import { WindowContext } from "../../../context/WindowContext"
import { clamp, formatDecimalNumber } from "../../../utils/MathUtils"
import { Decimal } from "@kit.ArkTS"

export enum CounterChangeMode {

  /**
   * 通过加减按钮修改时触发
   */
  Button,
  /**
   * 通过文本输入框修改时触发
   */
  Input,
  /**
   * 通过滑动屏幕的手势修改时触发
   */
  Gesture,
  /**
   * 滑动屏幕的手势修改结束后触发
   */
  GestureFinish,
  /**
   * 通过重置按钮恢复到重置值时触发
   */
  Reset

}

export class CounterController {

  private context: CounterContext | undefined = undefined
  private min: number = 0
  private max: number = 0

  init(context: CounterContext, min: number, max: number) {
    if (this.context)
      return
    this.context = context
    this.min = min
    this.max = max
  }

  public setValue(value: number) {
    if (!this.context)
      return
    this.context.value = clamp(value, this.min, this.max)
  }

}

@ComponentV2
export struct RohyCounter {

  /**
   * 最小值
   */
  @Param
  @Require
  min: number
  /**
   * 最大值
   */
  @Param
  @Require
  max: number

  /**
   * 步长，不推荐设置为小数值
   */
  @Param
  step: number = 1
  /**
   * 初始值
   */
  @Param
  initial: number = 0
  /**
   * 重置值，设置了此项且不为 undefined 时会显示一个重置按钮
   */
  @Param
  reset?: number = undefined
  /**
   * 用加减号替换左右箭头符号
   */
  @Param
  operatorIcons: boolean = false
  /**
   * 控制器，开发者可以通过此控制器来外部操作 Counter 的数值
   */
  @Param
  controller: CounterController = new CounterController()

  /**
   * 监听数据变化的函数
   */
  @Event
  onChange: (value: number, mode: CounterChangeMode) => void

  @Local
  private context: CounterContext = new CounterContext()

  @Local
  private aboutToDie: boolean = false

  aboutToAppear() {
    if (this.min > this.max)
      throw Error()
    this.context.value = clamp(this.initial, this.min, this.max)
    this.controller.init(this.context, this.min, this.max)
  }

  aboutToDisappear(): void {
    this.aboutToDie = true
  }

  build() {
    Row() {
      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph(this.operatorIcons ? $r('sys.symbol.minus') : $r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r("sys.color.icon_primary")])
          .symbolEffect(new BounceSymbolEffect(EffectScope.LAYER, EffectDirection.DOWN))
      }
      .clickEffect({
        level: ClickEffectLevel.LIGHT,
        scale: 0.8
      })
      .align(Alignment.Center)
      .width(36)
      .height(36)
      .enabled(this.context.value > this.min)
      .onClick(() => {
        if (this.aboutToDie)
          return
        let newValue = Math.max(this.min, formatDecimalNumber(this.context.value -= Math.abs(this.step), Math.abs(this.step)))
        if (this.context.value != newValue) {
          this.context.value = newValue
          this.onChange(this.context.value, CounterChangeMode.Button)
        }
      })
      .backgroundColor($r("sys.color.comp_background_tertiary"))
      Text(`${this.context.value}`)
        .margin({
          left: 8,
          right: 8
        })
        .constraintSize({
          minWidth: 24
        })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          DialogHelper.showTextInputDialog({
            inputType: InputType.NUMBER_DECIMAL,
            primaryTitle: $r("app.string.please_input_number"),
            text: `${this.context.value}`,
            buttons: [
              $r("app.string.confirm"),
              $r("app.string.cancel"),
            ],
            onAction: (action: number, dialogId: string, value: string): void => {
              DialogHelper.closeDialog(dialogId)
              if (this.aboutToDie)
                return
              if (action === -1) {
                try {
                  let numberValue = formatDecimalNumber(parseFloat(value) || 0, Math.abs(this.step))
                  let newValue = clamp(numberValue, this.min, this.max)
                  if (this.context.value != newValue) {
                    this.context.value = newValue
                    this.onChange(this.context.value, CounterChangeMode.Input)
                  }
                } catch (_) {
                }
              }
            }
          })
        })
      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph(this.operatorIcons ? $r('sys.symbol.plus') : $r('sys.symbol.chevron_right'))
          .fontSize(24)
          .fontColor([$r("sys.color.icon_primary")])
          .symbolEffect(new BounceSymbolEffect(EffectScope.LAYER, EffectDirection.DOWN))
      }
      .clickEffect({
        level: ClickEffectLevel.LIGHT,
        scale: 0.8
      })
      .align(Alignment.Center)
      .width(36)
      .height(36)
      .enabled(this.context.value < this.max)
      .onClick(() => {
        if (this.aboutToDie)
          return
        let newValue = Math.min(this.max, formatDecimalNumber(this.context.value += Math.abs(this.step), Math.abs(this.step)))
        if (this.context.value != newValue) {
          this.context.value = newValue
          this.onChange(this.context.value, CounterChangeMode.Button)
        }
      })
      .backgroundColor($r("sys.color.comp_background_tertiary"))
      if (this.reset !== undefined) {
        Button({
          type: ButtonType.Circle
        }) {
          SymbolGlyph($r('sys.symbol.arrow_clockwise'))
            .fontSize(24)
            .fontColor([$r("sys.color.icon_primary")])
            .symbolEffect(new BounceSymbolEffect(EffectScope.LAYER, EffectDirection.DOWN))
        }
        .clickEffect({
          level: ClickEffectLevel.LIGHT,
          scale: 0.8
        })
        .margin({
          left: 4
        })
        .align(Alignment.Center)
        .width(36)
        .height(36)
        .enabled(this.context.value != this.reset)
        .onClick(() => {
          if (this.aboutToDie)
            return
          this.context.value = this.reset!
          this.onChange(this.context.value, CounterChangeMode.Reset)
        })
        .backgroundColor($r("sys.color.comp_background_tertiary"))
      }
    }
    .gestureModifier(new CounterGestureModifier(this.getUIContext(), Math.abs(this.step), (delta) => {
      if (this.aboutToDie)
        return
      let newValue = clamp(formatDecimalNumber(this.context.value + delta, Math.abs(this.step)), this.min, this.max)
      if (this.context.value != newValue) {
        this.context.value = newValue
        this.onChange(this.context.value, CounterChangeMode.Gesture)
      }
    }, () => {
      if (this.aboutToDie)
        return
      this.onChange(this.context.value, CounterChangeMode.GestureFinish)
    }))
  }

}

@ObservedV2
class CounterContext {

  @Trace
  value: number = 0

}

class CounterGestureModifier implements GestureModifier {

  private context: UIContext
  private windowContext: WindowContext
  private step: number
  private onDelta: (delta: number) => void
  private onFinish: () => void

  private fingerOffsetX: number = -1

  constructor(context: UIContext, step: number, onDelta: (delta: number) => void, onFinish: () => void) {
    this.context = context
    this.windowContext = WindowContext.reach(this.context)
    this.step = Math.abs(step)
    this.onDelta = onDelta
    this.onFinish = onFinish
  }

  applyGesture(event: UIGestureEvent): void {
    event.addGesture(
      new PanGestureHandler({ fingers: 1, direction: PanDirection.Horizontal })
        .onActionStart((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          this.fingerOffsetX = -1
        })
        .onActionUpdate((event: GestureEvent) => {
          if (event.fingerList.length == 0) {
            return
          }
          let finger = event.fingerList[0]
          if (this.fingerOffsetX < 0) {
            this.fingerOffsetX = finger.globalX
            return
          }
          let oneStepLength = this.windowContext.widthVp / 100
          let realOffset = finger.globalX - this.fingerOffsetX
          if (Math.abs(realOffset) < oneStepLength) // 当移动距离超过最小 step 距离后才重新修改
            return
          this.fingerOffsetX = finger.globalX
          if (realOffset > 0)
            this.onDelta(this.step)
          else
            this.onDelta(-this.step)
        })
        .onActionEnd((event: GestureEvent) => {
          this.fingerOffsetX = -1
          this.onFinish()
        })
    )
  }

}
import { AbilityStorage } from '../storage/AbilityStorage'
import { window as win } from '@kit.ArkUI'

@ObservedV2
export class WindowContext {
  @Trace
  window: win.Window
  @Trace
  widthBreakpoint: string = ''
  @Trace
  heightBreakpoint: string = ''
  @Trace
  widthPx: number = 0
  @Trace
  heightPx: number = 0
  @Trace
  widthVp: number = 0
  @Trace
  heightVp: number = 0
  @Trace
  bottomAvoid: number = 0
  @Trace
  topAvoid: number = 0
  @Trace
  windowStatusType: win.WindowStatusType = win.WindowStatusType.UNDEFINED

  constructor(window: win.Window) {
    this.window = window
  }
}

export class Win {
  public static get(context: UIContext | Context, window?: win.Window): WindowContext {
    return AbilityStorage.connect(
      context,
      WindowContext,
      "window_context",
      () => new WindowContext(window!)
    )!
  }
}
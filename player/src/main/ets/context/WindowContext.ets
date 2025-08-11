import { AbilityStorage } from '../storage/AbilityStorage'
import { window } from '@kit.ArkUI'

@ObservedV2
export class WindowContext {
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
  windowStatusType: window.WindowStatusType = window.WindowStatusType.UNDEFINED
}

export class Win {
  public static get(context: UIContext | Context): WindowContext {
    return AbilityStorage.connect(
      context,
      WindowContext,
      "window_context",
      () => new WindowContext()
    )!
  }
}
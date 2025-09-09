import { AbilityStorage } from '../storage/AbilityStorage'
import { window as win } from '@kit.ArkUI'
import { ability } from '../utils/AbilityUtils'

@ObservedV2
export class WindowContext {
  @Trace
  window?: win.Window
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
  cutoutAvoid: number = 0
  @Trace
  staticBottomAvoid: number = 0
  @Trace
  staticTopAvoid: number = 0
  @Trace
  bottomAvoid: number = 0
  @Trace
  topAvoid: number = 0
  @Trace
  windowStatusType: win.WindowStatusType = win.WindowStatusType.UNDEFINED

  public static reach(context: UIContext | Context): WindowContext {
    return AbilityStorage.connect(
      context,
      WindowContext,
      "window_context",
      () => new WindowContext()
    )!
  }

}
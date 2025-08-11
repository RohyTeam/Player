import { display, window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Win } from '../../context/WindowContext';
import { abilityWindow } from '../../utils/AbilityUtils';

export class WindowManager {
  public static init(context: Context, windowObj: window.Window) {
    let rect = windowObj.getWindowProperties().windowRect
    WindowManager.updateWindowSize(context, rect.width, rect.height)
    WindowManager.updateAvoidArea(
      context,
      window.AvoidAreaType.TYPE_SYSTEM,
      windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    )
    WindowManager.updateAvoidArea(
      context,
      window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR,
      windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
    )
    WindowManager.updateWindowStatusType(context, windowObj.getWindowStatus())
    windowObj.on('windowSizeChange', (size: window.Size) => {
      WindowManager.updateWindowSize(context, size.width, size.height)
    })
    windowObj.on('avoidAreaChange', (options: window.AvoidAreaOptions) => {
      WindowManager.updateAvoidArea(context, options.type, options.area)
    })
    windowObj.on('windowStatusChange', (type: window.WindowStatusType) => {
      WindowManager.updateWindowStatusType(context, type)
    })
  }

  public static setFullscreen(context: UIContext | Context, status: boolean) {
    abilityWindow(context).setWindowLayoutFullScreen(status).then(() => {
      hilog.info(0x0, "window", `window layout fullscreen status set to ${status}`)
    })
  }

  public static setStatusBar(context: UIContext | Context, status: boolean) {
    abilityWindow(context).setSpecificSystemBarEnabled('status', status).then(() => {
      hilog.info(0x0, "window", `system status bar status set to ${status}`)
    })
  }

  public static setNavigationIndicator(context: UIContext | Context, status: boolean) {
    abilityWindow(context).setSpecificSystemBarEnabled('navigationIndicator', status).then(() => {
      hilog.info(0x0, "window", `system navigation indicator status set to ${status}`)
    })
  }

  public static setOrientation(context: UIContext | Context, orientation: window.Orientation) {
    abilityWindow(context).setPreferredOrientation(orientation)
  }

  private static updateWindowStatusType(context: UIContext | Context, type: WindowStatusType) {
    Win.get(context).windowStatusType = type
  }

  private static updateAvoidArea(context: UIContext | Context, type: window.AvoidAreaType, area: window.AvoidArea) {
    let windowContext = Win.get(context)
    if (type === window.AvoidAreaType.TYPE_SYSTEM) {
      windowContext.topAvoid = area.topRect.height
    } else if (type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      windowContext.bottomAvoid = area.bottomRect.height
    }
  }

  private static updateWindowSize(context: UIContext | Context, width: number, height: number): void {
    let windowContext = Win.get(context)

    let windowWidthVp = width / display.getDefaultDisplaySync().densityPixels;
    let windowHeightVp = height / display.getDefaultDisplaySync().densityPixels;
    let heightBp: string = '';
    let widthBp: string = '';
    let aspectRatio: number = windowHeightVp / windowWidthVp;
    if (aspectRatio < 0.8) {
      heightBp = 'sm';
    } else if (aspectRatio >= 0.8 && aspectRatio < 1.2) {
      heightBp = 'md';
    } else {
      heightBp = 'lg';
    }
    if (windowWidthVp < 320) {
      widthBp = 'xs';
    } else if (windowWidthVp >= 320 && windowWidthVp < 600) {
      widthBp = 'sm';
    } else if (windowWidthVp >= 600 && windowWidthVp < 840) {
      widthBp = 'md';
    } else if (windowWidthVp >= 840 && windowWidthVp < 1440) {
      widthBp = 'lg';
    } else {
      widthBp = 'xl';
    }

    windowContext.widthBreakpoint = widthBp
    windowContext.heightBreakpoint = heightBp
    windowContext.widthPx = width
    windowContext.heightPx = height
    windowContext.widthVp = windowWidthVp
    windowContext.heightVp = windowHeightVp
  }
}
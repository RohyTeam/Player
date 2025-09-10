import { display, window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WindowContext } from '../../context/WindowContext';
import { ability, abilityKey, abilityWindow, ensureContext } from '../../utils/AbilityUtils';
import { JSON } from '@kit.ArkTS';

export class WindowManager {
  public static init(context: Context, windowObj: window.Window) {
    WindowContext.reach(context).window = windowObj
    let rect = windowObj.getWindowProperties().windowRect
    WindowManager.updateWindowSize(context, rect.width, rect.height)
    WindowManager.updateStaticAvoidArea(
      context,
      window.AvoidAreaType.TYPE_SYSTEM,
      windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    )
    WindowManager.updateStaticAvoidArea(
      context,
      window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR,
      windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
    )
    WindowManager.updateStaticAvoidArea(
      context,
      window.AvoidAreaType.TYPE_CUTOUT,
      windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT)
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

  public static updateManually(rawContext: UIContext | Context) {
    let playerAbility = ability(rawContext)
    WindowManager.updateAvoidArea(
      playerAbility.context,
      window.AvoidAreaType.TYPE_SYSTEM,
      playerAbility.getWindow().getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
    )
    WindowManager.updateAvoidArea(
      playerAbility.context,
      window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR,
      playerAbility.getWindow().getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR)
    )
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
    WindowContext.reach(context).windowStatusType = type
  }

  private static updateAvoidArea(context: UIContext | Context, type: window.AvoidAreaType, area: window.AvoidArea) {
    let windowContext = WindowContext.reach(context)
    if (type == window.AvoidAreaType.TYPE_SYSTEM) {
      let vp = px2vp(area.topRect.height)
      windowContext.topAvoid = vp
    } else if (type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      let vp = px2vp(area.bottomRect.height)
      windowContext.bottomAvoid = vp
    } else if (type == window.AvoidAreaType.TYPE_CUTOUT) {
      windowContext.topCutoutAvoid = px2vp(area.topRect.height)
      windowContext.bottomCutoutAvoid = px2vp(area.bottomRect.height)
      windowContext.leftCutoutAvoid = px2vp(area.leftRect.width)
      windowContext.rightCutoutAvoid = px2vp(area.rightRect.width)
      console.error(`updating cutout, left: ${windowContext.leftCutoutAvoid}, right: ${windowContext.rightCutoutAvoid}, top: ${windowContext.topCutoutAvoid}, bottom: ${windowContext.bottomCutoutAvoid}`)
    }
  }

  private static updateStaticAvoidArea(context: UIContext | Context, type: window.AvoidAreaType, area: window.AvoidArea) {
    let windowContext = WindowContext.reach(context)
    if (type == window.AvoidAreaType.TYPE_SYSTEM) {
      let vp = px2vp(area.topRect.height)
      windowContext.staticTopAvoid = vp
    } else if (type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
      let vp = px2vp(area.bottomRect.height)
      windowContext.staticBottomAvoid = vp
    } else if (type == window.AvoidAreaType.TYPE_CUTOUT) {
      let vp = px2vp(area.topRect.height)
      windowContext.cutoutAvoid = vp
    }
  }

  private static updateWindowSize(context: UIContext | Context, width: number, height: number): void {
    let windowContext = WindowContext.reach(context)

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
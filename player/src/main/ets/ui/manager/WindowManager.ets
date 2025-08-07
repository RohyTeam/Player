import { AppStorageV2, display, window } from "@kit.ArkUI";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { WindowContext } from "../../context/WindowContext";
import { AbilityStorage } from "../../storage/AbilityStorage";
import { common } from "@kit.AbilityKit";
import { abilityWindow } from "../../utils/AbilityUtils";

export class WindowManager {

  public static init(context: Context, window: window.Window) {
    let rect = window.getWindowProperties().windowRect
    WindowManager.updateWindowSize(context, rect.width, rect.height)
    window.on('windowSizeChange', (size: window.Size) => {
      WindowManager.updateWindowSize(context, size.width, size.height)
    })
    window.on('avoidAreaChange', (options: window.AvoidAreaOptions) => {

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

  private static updateWindowSize(context: UIContext | Context, width: number, height: number): void {
    console.error(`updating window size: ${width}, ${height}`)
    let windowContext = AbilityStorage.connect(
      context,
      WindowContext,
      "window_context",
      () => new WindowContext()
    )!
    console.error(`caodabi`)

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

    console.error(`caoxiaobi`)

    windowContext.widthBreakpoint = widthBp
    windowContext.heightBreakpoint = heightBp
    windowContext.widthPx = width
    windowContext.heightPx = height
    windowContext.widthVp = windowWidthVp
    windowContext.heightVp = windowHeightVp
  }

}
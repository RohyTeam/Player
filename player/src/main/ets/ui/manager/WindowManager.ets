import { AppStorageV2, display, window } from "@kit.ArkUI";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { Win } from "../../context/WindowContext";

export class WindowManager {

  private static windowObj?: window.Window;

  public static init(window: window.Window) {
    WindowManager.windowObj = window
    let rect = window.getWindowProperties().windowRect
    WindowManager.updateWindowSize(rect.width, rect.height)
    WindowManager.windowObj.on('windowSizeChange', (size: window.Size) => {
      WindowManager.updateWindowSize(size.width, size.height)
    })
    WindowManager.windowObj.on('avoidAreaChange', (options: window.AvoidAreaOptions) => {

    })
  }

  public static setFullscreen(status: boolean) {
    WindowManager.windowObj?.setWindowLayoutFullScreen(status).then(() => {
      hilog.info(0x0, "window", `window layout fullscreen status set to ${status}`)
    })
  }

  public static setStatusBar(status: boolean) {
    WindowManager.windowObj?.setSpecificSystemBarEnabled('status', status).then(() => {
      hilog.info(0x0, "window", `system status bar status set to ${status}`)
    })
  }

  public static setNavigationIndicator(status: boolean) {
    WindowManager.windowObj?.setSpecificSystemBarEnabled('navigationIndicator', status).then(() => {
      hilog.info(0x0, "window", `system navigation indicator status set to ${status}`)
    })
  }

  private static updateWindowSize(width: number, height: number): void {
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

    Win.widthBreakpoint = widthBp
    Win.heightBreakpoint = heightBp
    Win.widthPx = width
    Win.heightPx = height
    Win.widthVp = windowWidthVp
    Win.heightVp = windowHeightVp
  }

}
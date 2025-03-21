import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { AppUtil, PreferencesUtil } from '@pura/harmony-utils';
import { DatabaseManager } from '../database/DatabaseManager';
import { ToolbarOptions } from '../util/ToolbarCustomizationUtil';
import { Rlog } from '../log/Rlog';

export default class PlayerAbility extends UIAbility {
  private windowObj?: window.Window;

  private updateHeightBp(): void {
    if (this.windowObj === undefined) {
      return;
    }
    let mainWindow: window.WindowProperties = this.windowObj.getWindowProperties();
    let windowHeight: number = mainWindow.windowRect.height;
    let windowWidth: number = mainWindow.windowRect.width;
    let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
    let windowHeightVp = windowHeight / display.getDefaultDisplaySync().densityPixels;
    let heightBp: string = '';
    let aspectRatio: number = windowHeightVp / windowWidthVp;
    if (aspectRatio < 0.8) {
      heightBp = 'sm';
    } else if (aspectRatio >= 0.8 && aspectRatio < 1.2) {
      heightBp = 'md';
    } else {
      heightBp = 'lg';
    }
    AppStorage.setOrCreate('currentHeightBreakpoint', heightBp);
  }

  private updateWidthBp(): void {
    if (this.windowObj === undefined) {
      return;
    }
    let mainWindow: window.WindowProperties = this.windowObj.getWindowProperties();
    let windowWidth: number = mainWindow.windowRect.width;
    let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
    let widthBp: string = '';
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
    AppStorage.setOrCreate('currentWidthBreakpoint', widthBp);
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppUtil.init(this.context)

    // 唯一一个在日志系统初始化前进行初始化的参数
    AppStorage.setOrCreate("save5logsOnly", PreferencesUtil.getBooleanSync("save5logsOnly", true))

    Rlog.startTracking(this.context)
    AppStorage.setOrCreate("RohyLoggingSystemInitialized", true)
    // 为了让直接从文件管理打开或者接续时也能保存日志，VideoAbility 也会添加日志初始化逻辑，但是为了保证只会初始化一次，添加存储变量

    // 这边如果用户没有调整过工具栏且是第一次打开，默认将所有工具栏都选中，同时因为横屏空间大，没有折叠功能，未选中的按钮直接隐藏
    if (!PreferencesUtil.hasSync('toolbar_landscape_topbar')) {
      PreferencesUtil.putSync('toolbar_landscape_topbar', ToolbarOptions.TOP_BAR.ALL_SELECTED)
    }
    if (!PreferencesUtil.hasSync('toolbar_landscape_bottombar')) {
      PreferencesUtil.putSync('toolbar_landscape_bottombar', ToolbarOptions.BOTTOM_BAR.ALL_SELECTED)
    }

    // 竖屏由于工具栏大小有限，仅允许选择 2 个外部按钮，剩下的全做折叠处理
    if (!PreferencesUtil.hasSync('toolbar_portrait_topbar')) {
      PreferencesUtil.putSync('toolbar_portrait_topbar', ToolbarOptions.TOP_BAR.PORTRAIT_DEFAULT_SELECTED)
    }
    if (!PreferencesUtil.hasSync('toolbar_portrait_bottombar')) {
      PreferencesUtil.putSync('toolbar_portrait_bottombar', ToolbarOptions.BOTTOM_BAR.PORTRAIT_DEFAULT_SELECTED)
    }

    let colorMode = PreferencesUtil.getStringSync("colorMode", "system")
    AppStorage.setOrCreate("debugMode", false)
    AppStorage.setOrCreate("appColorMode", colorMode)
    AppStorage.setOrCreate("autoShutdown", PreferencesUtil.getBooleanSync("autoShutdown", false))
    AppStorage.setOrCreate("statusBar", PreferencesUtil.getBooleanSync("statusBar", false))
    AppStorage.setOrCreate("statusBarBatteryPercent", PreferencesUtil.getBooleanSync("statusBarBatteryPercent", false))
    AppStorage.setOrCreate("preferFFmpeg", PreferencesUtil.getBooleanSync("preferFFmpeg", false))
    AppStorage.setOrCreate("hardwareDecode", PreferencesUtil.getBooleanSync("hardwareDecode", false))
    AppStorage.setOrCreate("lessCovering", PreferencesUtil.getBooleanSync("lessCovering", false))

    if (colorMode == "light") {
      this.context.config.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
    } else if (colorMode == "dark") {
      this.context.config.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK
    } else {
      this.context.config.colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    DatabaseManager.init(this.context)

    windowStage.getMainWindow().then((data: window.Window) => {
      this.windowObj = data;
      this.updateWidthBp();
      this.updateHeightBp();
      this.windowObj.on('windowSizeChange', (windowSize: window.Size) => {
        this.updateWidthBp();
        this.updateHeightBp();
      })
    })

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }
}
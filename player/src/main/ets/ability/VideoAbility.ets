import { AbilityConstant, UIAbility, Want } from "@kit.AbilityKit";
import { display, window } from "@kit.ArkUI";
import hilog from "@ohos.hilog";
import { BusinessError } from "@kit.BasicServicesKit";

interface EventData {
  launchWant: Want
}

/**
 * 此 Ability 为视频播放器的 Ability，仅支持横屏
 */
export default class VideoAbility extends UIAbility {

  private windowObj?: window.Window;

  private calculateWindowSize() {
    if (this.windowObj === undefined) {
      return;
    }
    let mainWindow: window.WindowProperties = this.windowObj.getWindowProperties();
    let windowWidth: number = mainWindow.windowRect.width;
    let windowHeight: number = mainWindow.windowRect.height;
    let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
    let windowHeightVp = windowHeight / display.getDefaultDisplaySync().densityPixels;
    console.error(`fuck fuck fuck screen height is ${windowHeight}, screen width is ${windowWidth}`)
    AppStorage.setOrCreate("screenWidth", mainWindow.windowRect.width)
    AppStorage.setOrCreate("screenHeight", mainWindow.windowRect.height)
    AppStorage.setOrCreate("screenHeightVp", windowHeightVp)
    AppStorage.setOrCreate("screenWidthVp", windowWidthVp)
  }

  /**
   * 处理 want
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    /**
     * 此处用于解决在 ability 中打开页面无法传参的问题
     */
    AppStorage.setOrCreate("comesFromApp", false)
    if (want.uri) { // 如果是通过传入文件来打开视频
      this.context.eventHub.on('getAbilityData', (data: EventData): void => {
        data.launchWant = {
          bundleName: 'org.rohy.player',
          abilityName: 'VideoAbility',
          parameters: {
            'url': want.uri!,
            'title': want.uri!
          }
        }
      })
    } else if (want.parameters) { // 如果是打开软件后通过 picker 打开视频
      this.context.eventHub.on('getAbilityData', (data: EventData): void => {
        data.launchWant = want
      })
      AppStorage.setOrCreate("comesFromApp", true)
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindow().then((data: window.Window) => {
      this.windowObj = data;
      this.windowObj.on('windowSizeChange', (windowSize: window.Size) => {
        this.calculateWindowSize()
      })
      data.setWindowKeepScreenOn(true);
    })

    windowStage.loadContent('pages/VideoIndex', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }

      let windowClass: window.Window = windowStage.getMainWindowSync()
      windowClass.setWindowLayoutFullScreen(true).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to set the window layout to full-screen mode. Code is ${err.code}, message is ${err.message}`);
      });

      windowClass.setSpecificSystemBarEnabled('status', false).then(() => {
        console.info('Succeeded in setting the status bar to be invisible.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to set the status bar to be invisible. Code is ${err.code}, message is ${err.message}`);
      });
      windowClass.setSpecificSystemBarEnabled('navigationIndicator', false).then(() => {
        console.info('Succeeded in setting the navigation indicator to be invisible.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to set the navigation indicator to be invisible. Code is ${err.code}, message is ${err.message}`);
      });

      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

}
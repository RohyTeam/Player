import { AbilityConstant, UIAbility, Want } from "@kit.AbilityKit";
import { display, window } from "@kit.ArkUI";
import hilog from "@ohos.hilog";
import { BusinessError, deviceInfo } from "@kit.BasicServicesKit";
import { EventData } from "../pages/VideoIndex";
import { connectDevice, copyFileToContinueDir, disconnectDevice } from "../util/ContinueUtil";
import { distributedDeviceManager } from "@kit.DistributedServiceKit";
import { JSON } from "@kit.ArkTS";
import { AppUtil, PreferencesUtil } from "@pura/harmony-utils";
import { checkPermissionGrant } from "../util/PermissionUtils";

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

    console.error(`screen width & height: ${windowWidth}, ${windowHeight}`)

    AppStorage.setOrCreate("screenWidth", mainWindow.windowRect.width)
    AppStorage.setOrCreate("screenHeight", mainWindow.windowRect.height)
    AppStorage.setOrCreate("screenHeightVp", windowHeightVp)
    AppStorage.setOrCreate("screenWidthVp", windowWidthVp)
  }

  /**
   * 应用接续
   * 搞得人头疼。。。
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult | Promise<AbilityConstant.OnContinueResult> {
    return new Promise((resultReturner) => {
      console.error("starting continue")
      let deviceManager = distributedDeviceManager.createDeviceManager("org.rohy.player")
      let eventData = new EventData()
      this.context.eventHub.emit('getAbilityData', eventData)
      let want = eventData.launchWant!
      wantParam['url'] = want.parameters!.url as string
      wantParam['title'] = want.parameters!.title as string
      wantParam['hash'] = want.parameters!.hash as string
      wantParam['videoPosition'] = AppStorage.get('videoPosition') || 0
      wantParam['videoPaused'] = AppStorage.get('videoPaused') || false
      if (want.parameters!['originalDevice'] == undefined) {
        console.error('not have original device')
        wantParam['originalDevice'] = deviceInfo.ODID
        wantParam['videoHolder'] = deviceManager.getLocalDeviceNetworkId()
        console.error('starting copy')
        copyFileToContinueDir(this.context, want.parameters!.url as string, want.parameters!.hash as string)
          .then(() => {
            console.error('done copy, go continue!')
            resultReturner(AbilityConstant.OnContinueResult.AGREE)
          })
      } else {
        console.error('do have original device')
        // 有这个参数说明这个视频被多次流转了，而且所有数据都已经填好，所以不进行任何改动
        wantParam['originalDevice'] = want.parameters!.originalDevice
        wantParam['videoHolder'] = want.parameters!.videoHolder
        resultReturner(AbilityConstant.OnContinueResult.AGREE)
      }
    })
  }

  /**
   * 处理 want
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    /**
     * 此处用于解决在 ability 中打开页面无法传参的问题
     */
    AppStorage.setOrCreate("comesFromApp", false)
    if (want.uri) {
      // 如果是通过传入文件来打开视频
      // 为了防止问题，未导入播放器的不进行接续支持
      // 关闭接续
      this.context.setMissionContinueState(AbilityConstant.ContinueState.INACTIVE, (result) => {
        console.info(`setMissionContinueState: ${JSON.stringify(result)}`);
      });
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
      AppStorage.setOrCreate("comesFromApp", true)
      // 如果用户没有授权分布式文件权限或者关闭了接续，关闭接续功能
      if (!checkPermissionGrant("ohos.permission.DISTRIBUTED_DATASYNC") || !tryGetPreference("continuation")) {
        console.error("user didnt turn on continuation")
        this.context.setMissionContinueState(AbilityConstant.ContinueState.INACTIVE, (result) => {
          console.info(`setMissionContinueState: ${JSON.stringify(result)}`);
        });
      }
      if (want.parameters!['videoPosition'] != undefined) {
        AppStorage.setOrCreate('videoPosition', want.parameters!.videoPosition as number)
        AppStorage.setOrCreate('videoPaused', want.parameters!.videoPaused as boolean)
      }
      this.context.eventHub.on('getAbilityData', (data: EventData): void => {
        data.launchWant = want
      })
    }
  }

  onWindowStageRestore(windowStage: window.WindowStage): void {
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

function tryGetPreference(key: string): boolean {
  try {
    // 因为如果是接续了话，AppUtil 不会被初始化，所以需要 try catch
    return PreferencesUtil.getBooleanSync(key, false)
  } catch (error) {
    return true // 如果出错了，说明是被接续过来的，那就应该允许被接续回去，所以返回 true
  }
}
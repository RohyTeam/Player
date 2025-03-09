import { AbilityConstant, common, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import hilog from '@ohos.hilog';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { EventData } from '../pages/VideoIndex';
import { copyFileToContinueDir } from '../util/ContinueUtil';
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
import { JSON } from '@kit.ArkTS';
import { AppUtil, PreferencesUtil } from '@pura/harmony-utils';
import { checkPermissionGrant } from '../util/PermissionUtils';
import { StringArray } from '../entity/Arrays';
import { Rlog } from '../log/Rlog';

/**
 * 此 Ability 为视频播放器的 Ability，仅支持横屏
 */
export default class VideoAbility extends UIAbility {
  private static windowObj?: window.Window;
  private static receivedWant?: Want
  private static context?: common.UIAbilityContext

  public static getContext(): common.UIAbilityContext {
    return VideoAbility.context!
  }

  public static getWindow(): window.Window {
    return VideoAbility.windowObj!
  }

  private calculateWindowSize() {
    if (VideoAbility.windowObj === undefined) {
      return;
    }
    let mainWindow: window.WindowProperties = VideoAbility.windowObj.getWindowProperties();
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
    // TODO：添加接续版本，防止后续更新新内容导致接续功能爆炸
    return new Promise((resultReturner) => {
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
        let uri = want.parameters!.url as string
        wantParam['originalVidUri'] = uri
        if (uri.startsWith('file://')) {
          copyFileToContinueDir(this.context, want.parameters!.url as string, want.parameters!.hash as string)
            .then(() => {
              resultReturner(AbilityConstant.OnContinueResult.AGREE)
            })
        } else if (uri.startsWith('http://') || uri.startsWith('https://')) {
          resultReturner(AbilityConstant.OnContinueResult.AGREE)
        } else {
          resultReturner(AbilityConstant.OnContinueResult.REJECT)
        }
      } else {
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
    VideoAbility.context = this.context
    if (!appUtilInited()) {
      // 这种情况一般是流转导致的，但是从文件预览打开也会导致这个情况
      console.error(`requires to reinit context`)
      AppUtil.init(this.context)
    }

    // 唯一一个在日志系统初始化前进行初始化的参数
    AppStorage.setOrCreate("save5logsOnly", PreferencesUtil.getBooleanSync("save5logsOnly", true))

    if (!(AppStorage.get('RohyLoggingSystemInitialized') || false)) {
      Rlog.startTracking(this.context)
    }

    let colorMode = PreferencesUtil.getStringSync("colorMode", "system")
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

    let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
    AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
    /**
     * 此处用于解决在 ability 中打开页面无法传参的问题
     */
    AppStorage.setOrCreate("comesFromApp", false)
    if (want.uri) {
      /* 由于权限问题，此功能暂时无效，所以先做屏蔽处理
      // 把视频导入到视频库里
      if (want.uri.startsWith("file://media")) { // 媒体库
        // TODO 因为我不确定媒体库里的是否能用别的软件打开，所以这一部分先不做
      } else if (want.uri.startsWith("file://")) { // 文件管理
        console.error(`starting importing an external video`)
        hash.hash(FileUtil.getFilePath(want.uri), "sha256")
          .then((fileHash) => {
            console.error(`video hashed, trying fetch from database`)
            // 即使能判断 PlayerAbility 是否启动，也没法从 VideoLibraryPage 中获取到缓存的文件哈希值列表，所以只能直接从数据库进行判断
            VideoLibraryDatabase.tryFetchByHash(this.context, fileHash)
              .then((result) => {
                if (result == undefined) {
                  console.error(`not exists, it's fine to add to library`)
                  VideoLibraryDatabase.addFromLocalFile(this.context, want.uri!)
                    .then(() => {
                      console.error(`ready to update video list if necessary`)
                      AppStorage.setOrCreate("videoUpdater", fileHash)
                    })
                    .catch((error: BusinessError) => {
                      console.error(`error occurs when trying to add file to database, code: ${error.code}, message: ${error.message}`)
                    })
                }
              })
              .catch((error: BusinessError) => {
                console.error(`error occurs when trying to fetch from database, code: ${error.code}, message: ${error.message}`)
              })
          })
          .catch((error: BusinessError) => {
            console.error(`error occurs when trying to hash the file, code: ${error.code}, message: ${error.message}`)
          })
      }*/
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
      VideoAbility.receivedWant = want
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
      VideoAbility.windowObj = data;
      VideoAbility.windowObj.on('windowSizeChange', (windowSize: window.Size) => {
        this.calculateWindowSize()
      })
      VideoAbility.windowObj.on('windowEvent', (windowEventType: window.WindowEventType) => {
        console.error(`current window event type: ${windowEventType}`)
        if (windowEventType == window.WindowEventType.WINDOW_HIDDEN) {
          let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
          shouldDies.push(VideoAbility.receivedWant?.parameters!.hash as string)
          AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
        }
      })
      data.setWindowKeepScreenOn(true);
    })

    windowStage.loadContent('pages/VideoIndex', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }

      let windowClass: window.Window = windowStage.getMainWindowSync()

      windowClass.setWindowLayoutFullScreen(true).then(() => { // 防止出现导航避让区
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error('Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
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
      VideoAbility.windowObj = data;
      VideoAbility.windowObj.on('windowSizeChange', (windowSize: window.Size) => {
        this.calculateWindowSize()
      })
      VideoAbility.windowObj.on('windowEvent', (windowEventType: window.WindowEventType) => {
        console.error(`current window event type: ${windowEventType}`)
        if (windowEventType == window.WindowEventType.WINDOW_HIDDEN) {
          let shouldDies: StringArray = AppStorage.get<StringArray>("videoAbility_shouldDie") || []
          shouldDies.push(VideoAbility.receivedWant?.parameters!.hash as string)
          AppStorage.setOrCreate("videoAbility_shouldDie", shouldDies)
        }
      })
      data.setWindowKeepScreenOn(true);
    })

    windowStage.loadContent('pages/VideoIndex', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }

      let windowClass: window.Window = windowStage.getMainWindowSync()

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

function appUtilInited(): boolean {
  try {
    return AppUtil.getContext() != undefined
  } catch (error) {
    return false
  }
}
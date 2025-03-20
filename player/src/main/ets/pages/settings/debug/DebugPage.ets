import { createClient } from '../../../lib/webdav_client/WebDAVClient'
import { Secrets } from '../../../Secrets'
import { openVideo } from '../../../util/PlayerUtil'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'
import { VirtualFilePicker, VirtualNode } from '../../components/VirtualFilePicker'
import { randomString } from '../../../util/StringUtil'
import { DraggableCustomization, DraggableCustomizationOption } from '../../components/DraggableCustomization'
import { ProgressLoadingOverlay } from '../../components/Overlays'
import { async } from '../../../util/AsyncUtil'
import { SettingsDivider, SettingsGroup, SettingsPage, SettingsRow } from '../../components/SettingsPage'
import { VideoLibraryDatabase } from '../../../database/VideoLibraryDatabase'
import { DatabaseManager } from '../../../database/DatabaseManager'
import { DialogHelper } from '@pura/harmony-dialog'

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

@Component
export struct DebugPage {
  @State
  private showVirtualPicker: boolean = false
  @Consume('pageController')
  pageController: NavPathStack

  @State
  private videosLoading: number = 1
  @State
  private videosLoaded: number = 0

  private loadingOverlay: CustomDialogController | null = new CustomDialogController({
    builder: ProgressLoadingOverlay({
      loading: this.videosLoading,
      loaded: this.videosLoaded
    }),
    autoCancel: false,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
        dismissDialogAction.dismiss()
      }
      if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
        dismissDialogAction.dismiss()
      }
    },
    alignment: DialogAlignment.Center,
    gridCount: 4,
    customStyle: false,
    cornerRadius: 16,
  })

  aboutToAppear(): void {
  }

  build() {
    NavDestination() {
      Column() {
        SettingsPage() {
          Blank()
            .height(12)
          SettingsGroup() {
            SettingsRow({
              settingsTitle: "测试文件 url",
              clickEvent: {
                action: () => {

                  let documentViewPicker = new picker.DocumentViewPicker(this.getUIContext().getHostContext()!);
                  const documentSelectOptions = new picker.DocumentSelectOptions();
                  documentSelectOptions.maxSelectNumber = 100;
                  documentSelectOptions.fileSuffixFilters = ['mp4 视频文件|.mp4', 'mkv 视频文件|.mkv', 'avi 视频文件|.avi'];

                  documentViewPicker.select(documentSelectOptions)
                    .then(async (documentSelectResult: Array<string>) => {
                      if (documentSelectResult.length == 0) {
                        return
                      }

                      for (let fileUrl of documentSelectResult) {
                        console.error(`file url is ${fileUrl}`)
                      }

                    }).catch((err: BusinessError) => {
                    console.error(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
                  })
                }
              }
            })
            SettingsDivider()
            SettingsRow({
              settingsTitle: "虚拟文件选择器测试",
              clickEvent: {
                action: () => {
                  this.showVirtualPicker = true
                }
              }
            })
              .bindSheet(
                $$this.showVirtualPicker,
                this.virtualFilePicker,
                {
                  showClose: false,
                  preferType: SheetType.CENTER,
                  shadow: ShadowStyle.OUTER_DEFAULT_MD,
                  enableOutsideInteractive: false,
                  shouldDismiss: (sheetDismiss) => {
                    sheetDismiss.dismiss()
                    this.showVirtualPicker = false
                  },
                  onWillDismiss: () => {
                    this.showVirtualPicker = false
                  },
                  backgroundColor: $r("app.color.rohy_settings_background")
                }
              )
            SettingsDivider()
            SettingsRow({
              settingsTitle: "工具栏编辑测试",
              clickEvent: {
                action: () => {
                  this.pageController.pushPath({ name: "toolbarCustomizer" })
                }
              }
            })
            SettingsDivider()
            SettingsRow({
              settingsTitle: "模糊效果测试",
              clickEvent: {
                action: () => {
                  this.pageController.pushPath({ name: "blurTest" })
                }
              }
            })
            SettingsDivider()
            SettingsRow({
              settingsTitle: "加载进度测试",
              clickEvent: {
                action: () => {
                  this.videosLoading = 100
                  this.videosLoaded = 0
                  this.loadingOverlay?.open()
                  async()
                    .then(() => {
                      this.videosLoadedAdd()
                    })
                }
              }
            })
            SettingsDivider()
            SettingsRow({
              settingsTitle: "删除所有源于图库的视频",
              titleColor: $r('app.color.alert'),
              clickEvent: {
                action: () => {
                  VideoLibraryDatabase.clearVideosFromPhotos(getContext(this))
                }
              }
            })
            SettingsDivider()
            SettingsRow({
              settingsTitle: "清除数据库",
              titleColor: $r('app.color.warning'),
              clickEvent: {
                action: () => {
                  DatabaseManager.clearAllDatabase(getContext(this))
                    .then(() => {
                      DialogHelper.showAlertDialog({
                        primaryTitle: "清除完毕",
                        content: "请重启应用，以确保数据完全清除",
                        autoCancel: false,
                        backCancel: false,
                        actionCancel: false,
                        primaryButton: {
                          value: "关闭应用",
                          fontColor: $r("app.color.font_primary"),
                          action: () => {
                            (getContext(this) as common.UIAbilityContext).terminateSelf()
                          }
                        },
                        onAction: (action: number, dialogId: string): void => {
                          DialogHelper.closeDialog(dialogId)
                        },
                        onWillDismiss: (): void => {
                          (getContext(this) as common.UIAbilityContext).terminateSelf()
                        },
                      })
                    })
                }
              }
            })
          }
        }
      }
      .width("100%")
      .height("100%")
    }
    .title('调试页')
    .width("100%")
    .height("100%")
  }

  private videosLoadedAdd() {
    sleep(200)
      .then(() => {
        this.videosLoaded += 1
        if (this.videosLoaded >= this.videosLoading) {
          this.loadingOverlay?.close()
        } else {
          this.videosLoadedAdd()
        }
      })
  }

  @Builder
  virtualFilePicker() {
    VirtualFilePicker({
      title: "测试",
      fileSystem: {
        listFiles: (path: string) => {
          return new Promise((resultReturner) => {
            let files: VirtualNode[] = [{
              displayName: "测试目录",
              name: "测试目录",
              size: -1,
              isDirectory: true
            }]
            for (let i = 0; i < 4; i++) {
              files.push({
                displayName: "测试文件",
                name: `测试文件 ${randomString(8)}`,
                size: -1,
                isDirectory: false
              })
            }
            resultReturner(files)
          })
        },
        visibleFilter: (node: VirtualNode) => {
          return true
        },
        onFileSelected: () => {
        }
      },
      show: $showVirtualPicker
    })
  }
}

@Component
export struct DebugToolbarCustomizer { // 横屏使用

  build() {
    NavDestination() {
      TopBarCustomizer()
    }
    .title($r('app.string.settings_toolbar'))
    .width("100%")
    .height("100%")
  }
}

@Component
struct TopBarCustomizer {
  private options: DraggableCustomizationOption[] = [
    {
      symbolIcon: $r('sys.symbol.rectangle'),
      name: $r('app.string.settings_toolbar_option_fillingmode'),
    },
    {
      symbolIcon: $r('sys.symbol.textformat'),
      name: $r('app.string.settings_toolbar_option_subtitles'),
    },
    {
      symbolIcon: $r('sys.symbol.timer'),
      name: $r('app.string.settings_toolbar_option_speed'),
    },
    {
      symbolIcon: $r('sys.symbol.speaker_wave_3'),
      name: $r('app.string.settings_toolbar_option_audios'),
    }
  ]

  build() {
    Column() {
      List({ space: 12 }) {
        ListItem() {
          DraggableCustomization({
            title: "测试调整 1",
            options: this.options,
            functions: {
              onChange: (selected: number[], unselected: number[]) => {

              }
            }
          })
        }

        ListItem() {
          DraggableCustomization({
            title: "调整限制测试",
            options: this.options,
            max: 2,
            functions: {
              onChange: (selected: number[], unselected: number[]) => {

              }
            }
          })
        }
      }
      .width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
  }
}

@Component
export struct BlurTestPage {
  build() {
    NavDestination() {
      Stack() {
        Row() {
          Column()
            .backgroundColor(Color.Red)
            .height("100%")
            .layoutWeight(1)
          Column()
            .backgroundColor(Color.Orange)
            .height("100%")
            .layoutWeight(1)
          Column()
            .backgroundColor(Color.Yellow)
            .height("100%")
            .layoutWeight(1)
          Column()
            .backgroundColor(Color.Green)
            .height("100%")
            .layoutWeight(1)
          Column()
            .backgroundColor("#00ffff")
            .height("100%")
            .layoutWeight(1)
          Column()
            .backgroundColor(Color.Blue)
            .height("100%")
            .layoutWeight(1)
          Column()
            .backgroundColor("#ff00ff")
            .height("100%")
            .layoutWeight(1)
        }
        .width("100%")
        .height("100%")

        Column() {
          Column()
            .width("100%")
            .layoutWeight(1)
            .opacity(0.5)
            .foregroundBlurStyle(
              BlurStyle.Thin,
              {
                scale: 0.1
              }
            )
            .backgroundColor(Color.White)
          Divider()
            .height(2)
          Column()
            .width("100%")
            .layoutWeight(1)
            .opacity(0.5)
            .foregroundBlurStyle(
              BlurStyle.Thin,
              {
                scale: 0.3
              }
            )
            .backgroundColor(Color.White)
          Divider()
            .height(2)
          Column()
            .width("100%")
            .layoutWeight(1)
            .opacity(0.5)
            .foregroundBlurStyle(
              BlurStyle.Thin,
              {
                scale: 0.5
              }
            )
            .backgroundColor(Color.White)
          Divider()
            .height(2)
          Column()
            .width("100%")
            .layoutWeight(1)
            .opacity(0.5)
            .foregroundBlurStyle(
              BlurStyle.Thin,
              {
                scale: 0.7
              }
            )
            .backgroundColor(Color.White)
          Divider()
            .height(2)
          Column()
            .width("100%")
            .layoutWeight(1)
            .opacity(0.5)
            .foregroundBlurStyle(
              BlurStyle.Thin,
              {
                scale: 1
              }
            )
            .backgroundColor(Color.White)
        }
      }
      .width("100%")
      .height("100%")
    }
    .title($r('app.string.settings_toolbar'))
    .width("100%")
    .height("100%")
  }
}

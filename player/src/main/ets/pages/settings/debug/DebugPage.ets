import { createClient } from '../../../lib/webdav_client/WebDAVClient'
import { Secrets } from '../../../Secrets'
import { openVideo } from '../../../util/PlayerUtil'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'
import { VirtualFilePicker, VirtualNode } from '../../components/VirtualFilePicker'
import { randomString } from '../../../util/StringUtil'
import { DraggableCustomization, DraggableCustomizationOption } from '../../components/DraggableCustomization'

@Component
export struct DebugPage {
  @State
  private showVirtualPicker: boolean = false
  @Consume('pageController')
  pageController: NavPathStack

  aboutToAppear(): void {
  }

  build() {
    NavDestination() {
      Column() {

        Button() {
          Text("测试文件 url")
            .fontSize(16)
            .margin(16)
        }
        .margin(16)
        .width("90%")
        .onClick(() => {

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
        })

        Button() {
          Text("测试在 ijk 中播放器 webdav 视频（请在设置里手动修改为 ijk 播放器）")
            .fontSize(16)
            .margin(16)
        }
        .margin(16)
        .width("90%")
        .onClick(() => {
          try {
            let client = createClient("", Secrets.WEBDAV_URL, {
              username: Secrets.WEBDAV_USERNAME,
              password: Secrets.WEBDAV_PASSWORD
            })
            client.authenticate()
              .then((result) => {
                if (result) {
                  client.authenticateFile('/动漫库/轻音少女/第一季/第 1 话 废部！.mkv')
                    .then((result) => {
                      openVideo(
                        getContext(this) as common.UIAbilityContext,
                        result.url,
                        '轻音少女 第 01 话',
                        Secrets.WEBDAV_VIDEO_HASH,
                        {
                          length: -1,
                          width: -1,
                          height: -1
                        },
                        result.headers
                      )
                    })
                } else {
                  console.error(`failed to authenticate`)
                }
              })
          } catch (err) {
            console.error(`error occurs when testing: ${JSON.stringify(err)}`)
          }
        })

        Button() {
          Text("虚拟文件选择器测试")
            .fontSize(16)
            .margin(16)
        }
        .margin(16)
        .width("90%")
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
        .onClick(() => {
          this.showVirtualPicker = true
        })

        Button() {
          Text("工具栏编辑测试")
            .fontSize(16)
            .margin(16)
        }
        .margin(16)
        .width("90%")
        .onClick(() => {
          this.pageController.pushPath({ name: "toolbarCustomizer" })
        })

        Button() {
          Text("模糊效果测试")
            .fontSize(16)
            .margin(16)
        }
        .margin(16)
        .width("90%")
        .onClick(() => {
          this.pageController.pushPath({ name: "blurTest" })
        })
      }
      .width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
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

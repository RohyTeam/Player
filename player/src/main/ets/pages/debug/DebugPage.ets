import { createClient } from '../../lib/webdav_client/WebDAVClient'
import { Secrets } from '../../Secrets'
import { openVideo } from '../../util/PlayerUtil'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { picker } from '@kit.CoreFileKit'
import { VirtualFilePicker, VirtualNode } from '../components/VirtualFilePicker'
import { randomString } from '../../util/StringUtil'

@Component
export struct DebugPage {
  @State
  private showVirtualPicker: boolean = false

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
              name: "测试目录",
              isDirectory: true
            }]
            for (let i = 0; i < 4; i++) {
              files.push({
                name: `测试文件 ${randomString(8)}`,
                isDirectory: false
              })
            }
            resultReturner(files)
          })
        },
        onFileSelected: () => {
        }
      },
      show: $showVirtualPicker
    })
  }
}
import { WebDAVAuthorization, WebDAVs } from '../../../entity/WebDAVEntity'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { DialogHelper } from '@pura/harmony-dialog'
import { WebDAVDatabase } from '../../../database/WebDAVDatabase'
import { createClient } from '../../../lib/webdav_client/WebDAVClient'

@Component
export struct WebDAVManagementGroup {
  @Link
  webdavs: WebDAVs
  @State
  displayNameValue: string = ""
  @State
  addressValue: string = ""
  @State
  usernameValue: string = ""
  @State
  passwordValue: string = ""
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: WebDAVAddDialog({
      displayNameValue: $displayNameValue,
      addressValue: $addressValue,
      usernameValue: $usernameValue,
      passwordValue: $passwordValue,
      functions: {
        cancel: () => {
          this.displayNameValue = ""
          this.addressValue = ""
          this.usernameValue = ""
          this.passwordValue = ""
        },
        confirm: () => {
          if (
            this.displayNameValue != "" &&
              this.addressValue != "" &&
              this.usernameValue != "" &&
              this.passwordValue != ""
          ) {
            let webdav: WebDAVAuthorization = {
              displayName: this.displayNameValue,
              url: this.addressValue,
              account: {
                username: this.usernameValue,
                password: this.passwordValue
              },
              died: false
            }
            WebDAVDatabase.addWebDAV(getContext(this), webdav)
              .then(() => {
                this.webdavs.push(webdav)
              })
          }
          this.displayNameValue = ""
          this.addressValue = ""
          this.usernameValue = ""
          this.passwordValue = ""
        }
      }
    }),
    autoCancel: true,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      console.info("reason=" + JSON.stringify(dismissDialogAction.reason))
      console.log("dialog onWillDismiss")
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
  @State
  private showingWebdavs: boolean = false

  aboutToAppear() {
    this.showingWebdavs = this.webdavs.length <= 5
  }

  build() {
    Column() {
      Row() {
        Stack() {
          SymbolGlyph($r("sys.symbol.arrowtriangle_down_fill"))
            .fontColor([$r("app.color.icon_primary")])
            .margin({
              left: 8,
              top: 8,
              bottom: 8
            })
            .width(24)
            .height(24)
            .fontSize(24)
        }
        .width(40)
        .height(40)
        .margin({
          left: 4,
          top: 4,
          bottom: 4
        })
        .rotate({
          z: 1,
          angle: !this.showingWebdavs ? -90 : 0
        })

        Text("WebDAV")// 我觉得这个没有必要进行本地化
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.font_primary"))
          .margin({
            top: 16,
            bottom: 16
          })
        Blank()
          .layoutWeight(1)
        Button({
          type: ButtonType.Normal,
        }) {
          Text($r("app.string.connect"))
            .fontColor($r("app.color.brand"))
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.dialogController?.open()
        })
        .margin(16)
      }
      .onClick(() => {
        animateTo({
          duration: 200,
          curve: Curve.Linear,
          playMode: PlayMode.Normal
        }, () => {
          this.showingWebdavs = !this.showingWebdavs
        })
      })
      .width("100%")

      if (this.showingWebdavs) {
        ForEach(this.webdavs, (webdav: WebDAVAuthorization) => {
          WebDAVRow({
            webdavs: this.webdavs,
            webdav: webdav
          })
        })
      }
    }
    .borderRadius(12)
    .backgroundColor($r("app.color.rohy_card"))
    .width("90%")
  }

  aboutToDisappear() {
    this.dialogController = null
  }
}

interface WebDAVAddFunctions {
  cancel: () => void
  confirm: () => void
}

@CustomDialog
@Component
struct WebDAVAddDialog {
  @Link
  displayNameValue: string
  @Link
  addressValue: string
  @Link
  usernameValue: string
  @Link
  passwordValue: string
  @Prop
  functions: WebDAVAddFunctions
  controller?: CustomDialogController

  build() {
    Column() {
      Text($r("app.string.webdav_dialog_title"))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 16 })
      TextInput({
        placeholder: $r("app.string.webdav_dialog_placeholder_display_name"),
        text: this.displayNameValue
      })
        .height(40)
        .width('90%')
        .margin({ bottom: 4 })
        .onChange((value: string) => {
          this.displayNameValue = value
        })
      TextInput({
        placeholder: $r("app.string.webdav_dialog_placeholder_url"),
        text: this.addressValue
      })
        .height(40)
        .width('90%')
        .margin({ bottom: 4 })
        .onChange((value: string) => {
          this.addressValue = value
        })
      TextInput({
        placeholder: $r("app.string.webdav_dialog_placeholder_username"),
        text: this.usernameValue
      })
        .height(40)
        .width('90%')
        .margin({ bottom: 4 })
        .onChange((value: string) => {
          this.usernameValue = value
        })
      TextInput({
        placeholder: $r("app.string.webdav_dialog_placeholder_password"),
        text: this.passwordValue
      })
        .contentType(ContentType.PASSWORD)
        .type(InputType.Password)
        .height(40)
        .width('90%')
        .margin({ bottom: 4 })
        .onChange((value: string) => {
          this.passwordValue = value
        })
      Flex({ justifyContent: FlexAlign.SpaceAround }) {
        Button($r("app.string.cancel"))
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.functions.cancel()
            }
          })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor($r("app.color.font_primary"))
        Divider()
          .vertical(true)
          .height(24)
          .margin(8)
        Button($r("app.string.confirm"))
          .onClick(() => {
            if (this.controller != undefined) {
              this.controller.close()
              this.functions.confirm()
            }
          })
          .layoutWeight(1)
          .backgroundColor(Color.Transparent)
          .fontColor($r("app.color.brand"))
      }
      .width('90%')
      .height(40)
      .margin({ bottom: 16 })
    }
    .borderRadius(16)
  }
}

@Component
struct WebDAVRow {
  @Link
  webdavs: WebDAVs
  @Prop
  webdav: WebDAVAuthorization
  @State
  deleted: boolean = false

  build() {
    if (!this.deleted) {
      Row() {
        Text(this.webdav.displayName)
          .margin(16)
          .fontSize(16)
        Blank()
          .layoutWeight(1)
        Button({
          type: ButtonType.Normal,
        }) {
          Text($r("app.string.test_connection"))
            .fontSize(14)
            .fontColor($r("app.color.brand"))
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          let webDAVClient = createClient("", this.webdav.url, this.webdav.account)
          webDAVClient.authenticate()
            .then((result) => {
              if (result) {
                promptAction.showToast({
                  'message': $r("app.string.test_connection_success")
                })
              } else {
                promptAction.showToast({
                  'message': $r("app.string.test_connection_failed")
                })
              }
            })
        })
        .margin(16)
      }
      .alignItems(VerticalAlign.Center)
      .bindContextMenu(this.contextMenu, ResponseType.LongPress)
      .width("100%")
    }
  }

  @Builder
  contextMenu() {
    Menu() {
      MenuItemGroup() {
        MenuItem()
        MenuItem() {
          Row() {
            Text($r("app.string.delete"))
              .fontColor($r("app.color.warning"))
              .fontWeight(FontWeight.Medium)
              .margin({
                left: 12,
                top: 14,
                bottom: 14
              })
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          DialogHelper.showAlertDialog({
            primaryTitle: $r("app.string.confirm_to_delete"),
            content: $r("app.string.confirm_to_delete_desc"),
            primaryButton: {
              value: $r("app.string.delete"),
              fontColor: $r("app.color.warning"),
              action: () => {
                let index = this.webdavs.findIndex((it) => it.url == this.webdav.url)
                if (index >= 0) {
                  this.webdavs.splice(index, 1)
                }
                this.deleted = true
                this.webdav.died = true
                WebDAVDatabase.deleteWebdavByUrl(getContext(this), this.webdav.url)
              }
            },
            secondaryButton: {
              value: $r("app.string.cancel"),
              fontColor: $r("app.color.brand")
            },
            onAction: (action: number, dialogId: string): void => {
              DialogHelper.closeDialog(dialogId)
            }
          })
        })
        .margin({
          top: 4,
          bottom: 4,
          left: 4,
          right: 4
        })
      }
    }
    .menuItemGroupDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
    })
    .padding(0)
  }
}
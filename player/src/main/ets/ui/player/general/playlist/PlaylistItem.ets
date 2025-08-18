import { DialogHelper } from "@pura/harmony-dialog"
import { PlaylistDao } from "../../../../database/dao/PlaylistDao"
import { isEmptyOrBlank } from "../../../../utils/StringUtils"
import { buildMenuGroup, menuGroups, RohyMenu } from "../../../component/menu/RohyMenu"
import { promptAction } from "@kit.ArkUI"
import { DataSources } from "../../../../datasource/DataSources"

@ComponentV2
export struct PlaylistItem {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  @Param
  @Require
  playlist: PlaylistDao

  build() {
    Button() {
      Column() {
        Image($r("app.media.hidisk_icon_folder"))
          .draggable(false)
          .aspectRatio(4 / 3)
          .width("100%")
          .margin({
            top: 8,
            left: 8,
            right: 8,
            bottom: 4
          })
        Text(this.playlist.name)
          .margin({
            bottom: 8,
            left: 8,
            right: 8
          })
      }
    }
    .bindContextMenu(this.contextMenu, ResponseType.LongPress)
    .bindContextMenu(this.contextMenu, ResponseType.RightClick)
    .onClick(() => {
      let params: Record<string, object> = {
        'dao': this.playlist,
        'path': []
      }
      this.indexNavigator.pushPath({ name: `PlaylistView`, param: params })
    })
    .borderRadius(16)
    .type(ButtonType.Normal)
    .backgroundColor(Color.Transparent)
  }

  @Builder
  private contextMenu() {
    RohyMenu({
      groups: menuGroups(() => [
        buildMenuGroup(() => [
          {
            options: {
              content: $r('app.string.rename')
            },
            action: () => {
              DialogHelper.showTextInputDialog({
                primaryTitle: $r("app.string.rename"),
                inputType: InputType.Normal,
                placeholder: $r("app.string.please_type_rename"),
                cancelButton: {
                  icon: {
                    color: $r("sys.color.icon_primary")
                  }
                },
                defaultFocus: true,
                onAction: (action: number, dialogId: string, rawValue: string): void => {
                  DialogHelper.closeDialog(dialogId)
                  // clicked confirm
                  if (action == -1) {
                    let value = rawValue.trim()
                    if (isEmptyOrBlank(value)) {
                      promptAction.showToast({
                        message: $r('app.string.name_cannot_be_blank')
                      })
                      return
                    }
                    if (DataSources.PLAYLIST.all().find((it) => it.name == value)) {
                      promptAction.showToast({
                        message: $r('app.string.name_duplicated')
                      })
                      return
                    }
                    DataSources.PLAYLIST.rename(this.playlist, value)
                    promptAction.showToast({
                      message: $r('app.string.rename_success')
                    })
                  }
                },
                buttons: [
                  {
                    value: $r("app.string.confirm"),
                    fontColor: $r("sys.color.brand"),
                  },
                  {
                    value: $r("app.string.cancel")
                  }
                ],
                text: this.playlist.name
              })
            }
          },
          {
            options: {
              content: $r('app.string.delete')
            },
            action: () => {
              DialogHelper.showAlertDialog({
                primaryTitle: $r("app.string.delete_confirm"),
                content: $r("app.string.delete_confirm_desc"),
                primaryButton: {
                  value: $r("app.string.delete"),
                  fontColor: $r("sys.color.warning"),
                  action: () => {
                    DataSources.PLAYLIST.remove(this.playlist)
                  }
                },
                secondaryButton: {
                  value: $r("app.string.cancel"),
                  fontColor: $r("sys.color.font_primary")
                },
                onAction: (action: number, dialogId: string): void => {
                  DialogHelper.closeDialog(dialogId)
                }
              })
            }
          }
        ])
      ])
    })
  }

}
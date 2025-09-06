import { DialogHelper } from '@pura/harmony-dialog'
import { PlaylistDao } from '../../../../database/dao/PlaylistDao'
import { PlaylistFolderItemsDataSource } from '../../../../datasource/playlist/PlaylistFolderItemsDataSource'
import {
  emptyPlaylistStructure,
  PlaylistFolder,
  PlaylistItem,
  PlaylistStructure,
  sortPlaylistItems
} from '../../../../playlist/PlaylistStructure'
import { isEmptyOrBlank } from '../../../../utils/StringUtils'
import { buildMenuGroup, menuGroups, RohyMenu } from '../../../component/menu/RohyMenu'
import { promptAction } from '@kit.ArkUI'

@ComponentV2
export struct PlaylistFolderItem {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Consumer("structure")
  structure: PlaylistStructure = emptyPlaylistStructure()
  @Consumer("folder")
  folder?: PlaylistFolder
  @Consumer("playlistFolderDataSource")
  playlistFolderDataSource?: PlaylistFolderItemsDataSource
  @Param
  @Require
  data: PlaylistDao
  @Param
  @Require
  path: number[]
  @Param
  @Require
  folderItem: PlaylistFolder

  build() {
    Button() {
      Column() {
        Image($r("app.media.hidisk_icon_folder"))
          .aspectRatio(4 / 3)
          .width("100%")
          .draggable(false)
          .margin({
            top: 8,
            left: 8,
            right: 8,
            bottom: 4
          })
        Text(this.folderItem.name)
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
        'dao': this.data,
        'path': this.subDir(this.folderItem)
      }
      this.indexNavigator.pushPath({ name: `PlaylistView`, param: params })
    })
    .borderRadius(16)
    .type(ButtonType.Normal)
    .backgroundColor(Color.Transparent)
  }

  private subDir(playlistItem: PlaylistItem): number[] {
    let newPath: number[] = []
    newPath.push(...this.path)
    newPath.push(this.folderItems().findIndex((it) => it.name == playlistItem.name))
    return newPath
  }

  private folderItems(): PlaylistItem[] {
    if (this.folder) {
      return sortPlaylistItems(this.folder.items)
    } else {
      return sortPlaylistItems(this.structure.items)
    }
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
                  if (!this.playlistFolderDataSource) {
                    return
                  }
                  // clicked confirm
                  if (action == -1) {
                    let value = rawValue.trim()
                    if (isEmptyOrBlank(value)) {
                      promptAction.showToast({
                        message: $r('app.string.name_cannot_be_blank')
                      })
                      return
                    }
                    if (this.playlistFolderDataSource.items().find((it) => it.name == value)) {
                      promptAction.showToast({
                        message: $r('app.string.name_duplicated')
                      })
                      return
                    }
                    this.playlistFolderDataSource.rename(this.folderItem.name, value)
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
                text: this.folderItem.name
              })
            }
          },
          {
            options: {
              content: $r('app.string.delete')
            },
            action: () => {
              if (!this.playlistFolderDataSource) {
                return
              }
              DialogHelper.showAlertDialog({
                primaryTitle: $r("app.string.delete_confirm"),
                content: $r("app.string.delete_confirm_desc"),
                primaryButton: {
                  value: $r("app.string.delete"),
                  fontColor: $r("sys.color.warning"),
                  action: () => {
                    this.playlistFolderDataSource!.deleteFolder(this.folderItem.name)
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
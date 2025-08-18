import { SavedVideoMetadata } from "../../../../metadata/SavedVideoMetadata"
import { VideoMetadataManager } from "../../../../metadata/VideoMetadataManager"
import { PlayerContext } from "../../../../player/PlayerContext"
import { LocalFileVideoSource } from "../../../../player/VideoSource"
import { PlaylistVideo } from "../../../../playlist/PlaylistStructure"
import { SimpleLoadingPage } from "../../../component/page/SimpleLoadingPage"
import { fileIo, fileShare } from "@kit.CoreFileKit"
import { image } from "@kit.ImageKit"
import { Modifiers } from "../../../attributemodifier/Modifiers"
import { convertNumberToDurationString } from "../../../../utils/NumberUtils"
import { buildMenuGroup, menuGroups, RohyMenu } from "../../../component/menu/RohyMenu"
import { DialogHelper } from "@pura/harmony-dialog"
import { isEmptyOrBlank } from "../../../../utils/StringUtils"
import { promptAction } from "@kit.ArkUI"
import { PlaylistFolderItemsDataSource } from "../../../../datasource/playlist/PlaylistFolderItemsDataSource"
import { ensurePath } from "../../../../utils/FileUtils"

@ComponentV2
export struct PlaylistVideoItem {

  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  @Consumer("playlistFolderDataSource")
  playlistFolderDataSource?: PlaylistFolderItemsDataSource

  @Param
  @Require
  video: PlaylistVideo

  @Local
  metadata?: SavedVideoMetadata

  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  build() {
    if (this.metadata) {
      Button() {
        Column() {
          Stack() {
            Image(this.metadata.metadata.cover as string)
              .draggable(false)
              .objectFit(ImageFit.Fill)
              .height("100%")
              .width("100%")
            Column() {
              Blank()
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
              Row() {
                Blank()
                  .backgroundColor(Color.Transparent)
                  .layoutWeight(1)
                Column() {
                  Text(convertNumberToDurationString(this.metadata.metadata.duration))
                }
                .borderRadius(6)
                .padding(2)
                .margin(2)
                .attributeModifier(Modifiers.backgroundBlur())
              }
              .backgroundColor(Color.Transparent)
            }
            .backgroundColor(Color.Transparent)
            .height("100%")
            .width("100%")
          }
          .clip(true)
          .aspectRatio(4 / 3)
          .width("100%")
          .margin({
            top: 8,
            left: 8,
            right: 8,
            bottom: 4
          })
          .borderRadius(8)
          Text(this.video.name)
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
        fileShare.activatePermission([{
          uri: this.video.url,
          operationMode: fileShare.OperationMode.READ_MODE
        }])
          .then(() => {
            this.playerContext.video = true
            this.playerContext.videoSource = new LocalFileVideoSource(
              true,
              this.metadata!,
              this.video.url,
              this.video.name
            )
            this.indexNavigator.pushPath({ name: "Player" })
          })
      })
      .borderRadius(16)
      .type(ButtonType.Normal)
      .backgroundColor(Color.Transparent)
    } else {
      Column() {
        SimpleLoadingPage()
      }
      .onAppear(() => {
        VideoMetadataManager.loadAsync(this.video.identity)
          .then((savedMetadata) => {
            if (!savedMetadata || !fileIo.accessSync(ensurePath(this.video.url), fileIo.AccessModeType.EXIST)) {
              // 这一步是判断如果这个视频不存在了就直接删除
              this.playlistFolderDataSource?.deleteVideo(this.video.identity)
              return
            }
            this.metadata = savedMetadata
          })
      })
      .aspectRatio(4 / 3)
      .width("100%")
      .margin({
        top: 8,
        left: 8,
        right: 8,
        bottom: 4
      })
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
                  if (!this.playlistFolderDataSource)
                    return
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
                    this.playlistFolderDataSource.rename(this.video.name, value)
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
                text: this.video.name
              })
            }
          },
          {
            options: {
              content: $r('app.string.delete')
            },
            action: () => {
              if (!this.playlistFolderDataSource)
                return
              DialogHelper.showAlertDialog({
                primaryTitle: $r("app.string.delete_confirm"),
                content: $r("app.string.delete_confirm_desc"),
                primaryButton: {
                  value: $r("app.string.delete"),
                  fontColor: $r("sys.color.warning"),
                  action: () => {
                    this.playlistFolderDataSource!.deleteVideo(this.video.identity)
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
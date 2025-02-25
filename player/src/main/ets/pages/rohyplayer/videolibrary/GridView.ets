import { FileSources, FileStatus, VideoEntityV2, VideoEntityV2Array } from '../../../entity/VideoEntity'
import common from '@ohos.app.ability.common'
import { BreakpointConstants } from '../../../common/constants/BreakpointConstants'
import { VideoDeleter } from './VideoLibraryPage'
import { fileIo, fileShare, hash } from '@kit.CoreFileKit'
import { convertNumberToDurationString } from '../../../util/TimeUtil'
import { FileUtil } from '@pura/harmony-utils'
import { LengthMetrics } from '@kit.ArkUI'
import { DialogHelper } from '@pura/harmony-dialog'
import { VideoLibraryDatabase } from '../../../database/VideoLibraryDatabase'
import { openVideo } from '../../../util/PlayerUtil'
import { showAlert } from '../../../util/AlertUtil'
import { arrayBufferToPixelMap } from '../../../util/ImageUtil'
import { Fonts } from '../../../entity/FontEntity'
import SubtitleManager from 'librohy_subtitle.so'

@Component
export struct GridView {
  @Link
  fonts: Fonts
  @Prop
  searching: string
  @ObjectLink
  videos: VideoEntityV2Array
  @Prop
  deleter: VideoDeleter
  @Link
  covers: Record<string, PixelMap>
  @StorageLink('currentWidthBreakpoint')
  currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;

  build() {
    Column() {
      Grid(
        undefined,
        {
          regularSize: [1, 1]
        }
      ) {
        ForEach(this.videos, (video: VideoEntityV2) => {
          if (this.searching.length == 0 ||
            video.title.indexOf(this.searching) >= 0 && video.status != FileStatus.Disappear) {
            GridItem() {
              VideoRow({
                fonts: this.fonts,
                deleter: this.deleter,
                covers: this.covers,
                video: video,
              })
                .onAppear(() => {
                  if (video.status == FileStatus.Authorized) {
                    this.convertCover(video)
                  } else if (video.status == FileStatus.None) {
                    if (video.fileSource == FileSources.LOCAL_FILE) {
                      fileShare.activatePermission([{
                        uri: video.uri,
                        operationMode: 0b1
                      }])
                        .then(() => {
                          hash.hash(FileUtil.getFilePath(video.uri), "sha256")
                            .then((fileHash) => {
                              if (fileHash != video.hash) {
                                video.status = FileStatus.Disappear
                                this.deleter.action(video)
                              } else {
                                if (video.length == -1) {
                                  VideoLibraryDatabase.updateVersion3ByHash(
                                    getContext(this),
                                    video.hash,
                                    video.uri
                                  )
                                    .then(() => {
                                      video.status = FileStatus.Authorized
                                      this.convertCover(video)
                                    })
                                } else {
                                  video.status = FileStatus.Authorized
                                  this.convertCover(video)
                                }
                              }
                            })
                        })
                        .catch(() => {
                          video.status = FileStatus.Disappear
                          this.deleter.action(video)
                        })
                    } else if (video.fileSource == FileSources.PHOTOS) {
                      // 由于用户无法直接修改视频在相册里的名称（除非删除）所以只验证文件是否存在，而不验证是否对的上哈希值
                      fileIo.open(video.uri)
                        .then((file) => {
                          if (video.length == -1) {
                            VideoLibraryDatabase.updateVersion3ByHash(
                              getContext(this),
                              video.hash,
                              video.uri
                            )
                              .then(() => {
                                video.status = FileStatus.Authorized
                                this.convertCover(video)
                              })
                          } else {
                            video.status = FileStatus.Authorized
                            this.convertCover(video)
                          }
                        })
                        .catch(() => {
                          video.status = FileStatus.Disappear
                          this.deleter.action(video)
                        })
                    }
                  }
                })
            }
          }
        })
      }
      .columnsTemplate(
        this.currentWidthBreakpoint == "xs" ? "1fr 1fr" : (
          this.currentWidthBreakpoint == "sm" ? "1fr 1fr" : (
            this.currentWidthBreakpoint == "md" ? "1fr 1fr 1fr 1fr" : (
              this.currentWidthBreakpoint == "lg" ? "1fr 1fr 1fr 1fr 1fr" : (
                this.currentWidthBreakpoint == "xl" ? "1fr 1fr 1fr 1fr 1fr 1fr 1fr" :
                  "1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr"
              )
            )
          )
        )
      )
      .edgeEffect(EdgeEffect.Spring)
      .expandSafeArea([SafeAreaType.SYSTEM],
        this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG ? [SafeAreaEdge.BOTTOM] : [])
      .rowsGap(8)
      .columnsGap(8)
      .layoutDirection(GridDirection.Row)
      .width("100%")
      .padding({
        left: "5%",
        right: "5%",
      })
      .borderRadius(12)
      .layoutWeight(1)
    }
    .width("100%")
    .height("100%")
  }

  private convertCover(video: VideoEntityV2) {
    if (this.covers[video.hash] == undefined) {
      arrayBufferToPixelMap(video.cover)
        .then((pixelMap) => {
          this.covers[video.hash] = pixelMap
        })
    }
  }
}


@Component
struct VideoRow {
  @Link
  fonts: Fonts
  @Prop
  deleter: VideoDeleter
  @ObjectLink
  video: VideoEntityV2
  @Link
  covers: Record<string, PixelMap>

  build() {
    if (this.video.status == FileStatus.Authorized) {
      Row() {
        Button() {
          Column() {
            if (this.covers[this.video.hash] != undefined) {
              Image(this.covers[this.video.hash])
                .width("100%")
                .aspectRatio(4 / 3)
                .borderRadius(10)
            }
            Text(this.video.title)
              .maxLines(1)
              .textOverflow({
                overflow: TextOverflow.Ellipsis
              })
              .fontSize(16)
              .margin({
                left: "8vp",
                right: "8vp",
                top: "4vp"
              })
            Text($r("app.string.duration",
              `${convertNumberToDurationString(this.video.length)}`))
              .fontSize(10)
              .fontColor($r("app.color.font_secondary"))
              .margin({
                left: "8vp",
                right: "8vp",
              })
            if (this.video.played == -1) {
              Text($r("app.string.played_status_no"))
                .fontSize(10)
                .fontColor($r("app.color.font_secondary"))
                .margin({
                  left: "8vp",
                  right: "8vp",
                  bottom: "8vp"
                })
            } else if (this.video.played >= this.video.length) {
              Text($r("app.string.played_status_all"))
                .fontSize(10)
                .fontColor($r("app.color.font_secondary"))
                .margin({
                  left: "8vp",
                  right: "8vp",
                  bottom: "8vp"
                })
            } else {
              Text($r("app.string.played_status_playing", `${Math.ceil(this.video.played / this.video.length * 100)}`))
                .fontSize(10)
                .fontColor($r("app.color.font_secondary"))
                .margin({
                  left: "8vp",
                  right: "8vp",
                  bottom: "8vp"
                })
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .onClick(() => {
          fileIo.open(this.video.uri)
            .then(() => {
              for (let font of this.fonts) {
                if (font.on && font.status == FileStatus.Authorized) {
                  let file = fileIo.openSync(font.uri)
                  const arrayBuffer = new ArrayBuffer(fileIo.statSync(file.fd).size);
                  fileIo.readSync(file.fd, arrayBuffer)
                  SubtitleManager.Subtitle_AddMemoryFont(font.familyName, arrayBuffer)
                }
              }
              if (this.video.played >= this.video.length) {
                AppStorage.setOrCreate("videoPosition", 0)
              } else {
                AppStorage.setOrCreate("videoPosition", this.video.played)
              }
              openVideo(getContext(this) as common.UIAbilityContext, this.video.uri, this.video.title, this.video.hash)
            })
            .catch(() => {
              this.video.status = FileStatus.Disappear
              this.deleter.action(this.video)
              showAlert(this.getUIContext(), $r("app.string.file_deleted"),
                $r("app.string.file_deleted_desc"))
            })
        })
        .bindContextMenu(this.contextMenu, ResponseType.LongPress)
        .type(ButtonType.Normal)
        .margin(4)
        .borderRadius(10)
        .backgroundColor($r("app.color.rohy_card"))
      }
      .borderRadius(12)
      .backgroundColor($r("app.color.rohy_card"))
    } else {
      Row() {
        Blank()
          .layoutWeight(1)
        LoadingProgress()
          .enableLoading(true)
          .color($r("app.color.icon_secondary"))
          .width(64)
          .height(64)
        Blank()
          .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .borderRadius(12)
      .backgroundColor($r("app.color.rohy_card"))
    }
  }

  @Builder
  contextMenu() {
    Menu() {
      MenuItemGroup() {
        MenuItem({
          content: $r("app.string.edit_name")
        })
          .onClick(() => {
            DialogHelper.showTextInputDialog({
              primaryTitle: $r("app.string.edit_name"),
              inputType: InputType.Normal,
              cancelButton: {
                icon: {
                  color: $r("app.color.icon_primary")
                }
              },
              text: this.video.title,
              onAction: (action: number, dialogId: string, value: string): void => {
                DialogHelper.closeDialog(dialogId)

                if (action == -1) {
                  VideoLibraryDatabase.updateNameByHash(getContext(this), this.video.hash, value)
                  this.deleter.renamer(this.video, value)
                }
              },
              buttons: [
                {
                  value: $r("app.string.confirm"),
                  fontColor: $r("app.color.brand"),
                },
                {
                  value: $r("app.string.cancel"),
                  fontColor: $r("app.color.brand")
                }
              ]
            })
          })
          .margin({
            top: 4,
            left: 4,
            right: 4
          })
        MenuItem()
      }

      MenuItemGroup() {
        MenuItem()
        MenuItem() {
          Row() {
            Text($r("app.string.delete"))
              .fontColor($r("app.color.warning"))
              .fontWeight(FontWeight.Medium)// .margin(12)
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
                this.video.status = FileStatus.Disappear
                this.deleter.action(this.video)
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
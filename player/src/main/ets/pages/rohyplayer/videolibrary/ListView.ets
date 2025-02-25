import { FileSources, FileStatus, VideoEntityV2, VideoEntityV2Array } from '../../../entity/VideoEntity'
import common from '@ohos.app.ability.common'
import { DialogHelper } from '@pura/harmony-dialog'
import { VideoDeleter } from './VideoLibraryPage'
import { fileIo, fileShare, hash } from '@kit.CoreFileKit'
import { VideoLibraryDatabase } from '../../../database/VideoLibraryDatabase'
import { FileUtil } from '@pura/harmony-utils'
import { convertNumberToDurationString } from '../../../util/TimeUtil'
import { BreakpointConstants } from '../../../common/constants/BreakpointConstants'
import { openVideo } from '../../../util/PlayerUtil'
import { showAlert } from '../../../util/AlertUtil'
import { arrayBufferToPixelMap } from '../../../util/ImageUtil'
import { Fonts } from '../../../entity/FontEntity'
import SubtitleManager from 'librohy_subtitle.so'

@Component
export struct ListView {
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
  private scroller = new ListScroller()
  @StorageLink('currentWidthBreakpoint')
  currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;

  build() {
    Column() {
      List({ space: 8, scroller: this.scroller }) {
        ForEach(this.videos, (video: VideoEntityV2) => {
          if (this.searching.length == 0 ||
            video.title.indexOf(this.searching) >= 0 && video.status != FileStatus.Disappear) {
            ListItem() {
              VideoRow({
                fonts: this.fonts,
                covers: this.covers,
                deleter: this.deleter,
                video: video,
              })
            }
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
            .swipeAction({
              end: {
                builder: () => {
                  this.swipeToRemoveButton(video)
                },
                onAction: () => {
                  DialogHelper.showAlertDialog({
                    primaryTitle: $r("app.string.confirm_to_delete"),
                    content: $r("app.string.confirm_to_delete_desc"),
                    primaryButton: {
                      value: $r("app.string.delete"),
                      fontColor: $r("app.color.warning"),
                      action: () => {
                        video.status = FileStatus.Disappear
                        this.deleter.action(video)
                      }
                    },
                    secondaryButton: {
                      value: $r("app.string.cancel"),
                      fontColor: $r("app.color.brand")
                    },
                    onAction: (action: number, dialogId: string): void => {
                      this.scroller.closeAllSwipeActions()
                      DialogHelper.closeDialog(dialogId)
                    }
                  })
                },
                actionAreaDistance: 72,
              }
            })
            .width("100%")
          }
        })
      }
      .edgeEffect(EdgeEffect.Spring)
      .expandSafeArea([SafeAreaType.SYSTEM],
        this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG ? [SafeAreaEdge.BOTTOM] : [])
      .borderRadius(12)
      .width("100%")
      .layoutWeight(1)
    }
    .width("100%")
    .height("100%")
  }

  @Builder
  swipeToRemoveButton(item: VideoEntityV2) {
    Row() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.paintbrush'))
          .fontWeight(FontWeight.Bold)
          .fontColor([$r("app.color.icon_primary")])
      }
      .width(40)
      .height(40)
      .margin({
        right: "16vp"
      })
      .onClick(() => {
        this.scroller.closeAllSwipeActions()
        DialogHelper.showTextInputDialog({
          primaryTitle: $r("app.string.edit_name"),
          inputType: InputType.Normal,
          cancelButton: {
            icon: {
              color: $r("app.color.icon_primary")
            }
          },
          text: item.title,
          onAction: (action: number, dialogId: string, value: string): void => {
            DialogHelper.closeDialog(dialogId)

            if (action == -1) {
              VideoLibraryDatabase.updateNameByHash(getContext(this), item.hash, value)
              this.deleter.renamer(item, value)
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
      .backgroundColor($r("app.color.comp_background_tertiary"))

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontWeight(FontWeight.Bold)
          .fontColor([$r("app.color.icon_on_primary")])
      }
      .width(40)
      .height(40)
      .margin({
        right: "24vp"
      })
      .onClick(() => {
        this.scroller.closeAllSwipeActions()
        DialogHelper.showAlertDialog({
          primaryTitle: $r("app.string.confirm_to_delete"),
          content: $r("app.string.confirm_to_delete_desc"),
          primaryButton: {
            value: $r("app.string.delete"),
            fontColor: $r("app.color.warning"),
            action: () => {
              item.status = FileStatus.Disappear
              this.deleter.action(item)
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
      .backgroundColor($r("app.color.warning"))
    }.justifyContent(FlexAlign.SpaceEvenly)
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
  @ObjectLink
  video: VideoEntityV2
  @Prop
  deleter: VideoDeleter
  @Link
  covers: Record<string, PixelMap>
  @StorageLink('currentWidthBreakpoint')
  currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;

  build() {
    if (this.video.status == FileStatus.Authorized) {
      Row() {
        Button() {
          Row() {
            if (this.covers[this.video.hash] != undefined) {
              Image(this.covers[this.video.hash])
                .width(80)
                .height(60)
                .margin(8)
                .borderRadius(5)
            }
            Column() {
              Text(this.video.title)
                .maxLines(1)
                .textOverflow({
                  overflow: TextOverflow.Ellipsis
                })
                .fontSize(16)
                .margin({
                  top: "10vp"
                })
              Blank()
                .layoutWeight(1)
              Row() {
                Text($r("app.string.duration",
                  `${convertNumberToDurationString(this.video.length)}`))
                  .fontSize(10)
                  .fontColor($r("app.color.font_secondary"))
                  .margin({
                    bottom: "10vp"
                  })
                Blank()
                  .layoutWeight(1)
                if (this.video.played == -1) {
                  Text($r("app.string.played_status_no"))
                    .fontSize(10)
                    .fontColor($r("app.color.font_secondary"))
                    .margin({
                      bottom: "10vp",
                      right: "10vp"
                    })
                } else if (this.video.played >= this.video.length) {
                  Text($r("app.string.played_status_all"))
                    .fontSize(10)
                    .fontColor($r("app.color.font_secondary"))
                    .margin({
                      bottom: "10vp",
                      right: "10vp"
                    })
                } else {
                  Text($r("app.string.played_status_playing",
                    `${Math.ceil(this.video.played / this.video.length * 100)}`))
                    .fontSize(10)
                    .fontColor($r("app.color.font_secondary"))
                    .margin({
                      bottom: "10vp",
                      right: "10vp"
                    })
                }
              }
              .width("100%")
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .height("100%")
          }
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
        .type(ButtonType.Normal)
        .margin(4)
        .borderRadius(10)
        .backgroundColor($r("app.color.rohy_card"))
      }
      .borderRadius(12)
      .height("84vp")
      .width("90%")
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
      .height("84vp")
      .width("90%")
      .backgroundColor($r("app.color.rohy_card"))
    }
  }
}
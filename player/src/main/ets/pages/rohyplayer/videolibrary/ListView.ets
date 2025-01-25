import { FileSources, FileStatus, VideoEntityV2, VideoEntityV2Array } from '../../../entity/VideoEntity'
import common from '@ohos.app.ability.common'
import { DialogHelper } from '@pura/harmony-dialog'
import { VideoDeleter } from './VideoLibraryPage'
import { media } from '@kit.MediaKit'
import { fileIo, fileShare, hash } from '@kit.CoreFileKit'
import { VideoLibraryDatabase } from '../../../database/VideoLibraryDatabase'
import { DateUtil, FileUtil } from '@pura/harmony-utils'
import { convertNumberToDurationString } from '../../../util/TimeUtil'
import { BreakpointConstants } from '../../../common/constants/BreakpointConstants'
import { openVideo } from '../../../util/PlayerUtil'
import { showAlert } from '../../../util/AlertUtil'

@Component
export struct ListView {
  @Prop
  searching: string
  @ObjectLink
  videos: VideoEntityV2Array
  @Prop
  deleter: VideoDeleter
  @Link
  covers: Record<string, PixelMap>
  @Link
  metadatas: Record<string, media.AVMetadata>
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
                covers: this.covers,
                deleter: this.deleter,
                metadatas: this.metadatas,
                video: video,
              })
            }
            .onAppear(() => {
              if (video.status == FileStatus.Authorized) {
                this.findMetadata(video)
                this.findCover(video)
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
                            video.status = FileStatus.Authorized
                            this.findMetadata(video)
                            this.findCover(video)
                          }
                        })
                    })
                    .catch(() => {
                      video.status = FileStatus.Disappear
                      this.deleter.action(video)
                    })
                } else if (video.fileSource == FileSources.PHOTOS) {
                  // 由于用户无法直接修改视频在相册里的名称（除非删除）所以只验证文件是否存在，而不验证是否对的上哈希值
                  fileIo.access(video.uri, fileIo.AccessModeType.EXIST)
                    .then((exist: boolean) => {
                      if (exist) {
                        video.status = FileStatus.Authorized
                      } else {
                        video.status = FileStatus.Disappear
                        this.deleter.action(video)
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

  private findMetadata(video: VideoEntityV2) {
    if (this.metadatas[video.hash] == undefined) {
      media.createAVMetadataExtractor().then((avMetadataExtractor: media.AVMetadataExtractor) => {
        fileIo.open(video.uri)
          .then((file) => {
            avMetadataExtractor.fdSrc = { fd: file.fd }
            avMetadataExtractor.fetchMetadata()
              .then((metadata) => {
                this.metadatas[video.hash] = metadata
                avMetadataExtractor.release()
              })
          })
          .catch(() => {
            video.status = FileStatus.Disappear
            this.deleter.action(video)
          })
      })
    }
  }

  private findCover(video: VideoEntityV2) {
    if (this.covers[video.hash] == undefined) {
      media.createAVImageGenerator().then((avImageGenerator: media.AVImageGenerator) => {
        fileIo.open(video.uri)
          .then((file) => {
            avImageGenerator.fdSrc = { fd: file.fd }
            let timeUs = 0
            let queryOption = media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC
            let param: media.PixelMapParams = {
              width: 720,
              height: 540
            }
            avImageGenerator.fetchFrameByTime(timeUs, queryOption, param)
              .then((pixelMap) => {
                this.covers[video.hash] = pixelMap
                avImageGenerator.release()
              })
          })
          .catch(() => {
            video.status = FileStatus.Disappear
            this.deleter.action(video)
          })
      })
    }
  }
}

@Component
struct VideoRow {
  @ObjectLink
  video: VideoEntityV2
  @Prop
  deleter: VideoDeleter
  @Link
  covers: Record<string, PixelMap>
  @Link
  metadatas: Record<string, media.AVMetadata>
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
              if (this.metadatas[this.video.hash] != undefined) {
                Text($r("app.string.duration",
                  `${convertNumberToDurationString(parseInt(this.metadatas[this.video.hash].duration))}`))
                  .fontSize(10)
                  .fontColor($r("app.color.font_secondary"))
              }
              Text($r("app.string.import_time", DateUtil.getFormatDateStr(this.video.addedTime)))
                .fontSize(10)
                .fontColor($r("app.color.font_secondary"))
                .margin({
                  bottom: "10vp"
                })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .height("100%")
          }
        }
        .onClick(() => {
          fileIo.open(this.video.uri)
            .then(() => {
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
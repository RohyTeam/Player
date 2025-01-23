import { FileStatus, VideoEntity, VideoEntityV2, VideoEntityV2Array } from "../../../entity/VideoEntity"
import Want from "@ohos.app.ability.Want"
import common from "@ohos.app.ability.common"
import { BreakpointConstants } from "../../../common/constants/BreakpointConstants"
import { media } from "@kit.MediaKit"
import { VideoDeleter } from "./VideoLibraryPage"
import { fileIo, fileShare, hash } from "@kit.CoreFileKit"
import { deviceInfo } from "@kit.BasicServicesKit"
import { CommonConstants } from "../../../common/constants/CommonConstants"
import { convertNumberToDurationString } from "../../../util/TimeUtil"
import { DateUtil, FileUtil } from "@pura/harmony-utils"
import { LengthMetrics } from "@kit.ArkUI"
import { DialogHelper } from "@pura/harmony-dialog"
import { VideoLibraryDatabase } from "../../../database/VideoLibraryDatabase"

@Component
export struct GridView {
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
          if (this.searching.length == 0 || video.title.indexOf(this.searching) >= 0 && video.status != FileStatus.Disappear) {
            GridItem() {
              VideoRow({
                deleter: this.deleter,
                covers: this.covers,
                metadatas: this.metadatas,
                video: video,
              })
                .onAppear(() => {
                  if (video.status == FileStatus.Authorized) {
                    this.findMetadata(video)
                    this.findCover(video)
                  } else if (video.status == FileStatus.None) {
                    fileShare.activatePermission([{
                      uri: video.uri,
                      operationMode: 0b1
                    }])
                      .then(() => {
                        hash.hash(FileUtil.getFilePath(video.uri), "sha256")
                          .then((fileHash) => {
                            if (fileHash != video.hash) {
                              VideoLibraryDatabase.deleteByHash(getContext(this), video.hash)
                            } else {
                              video.status = FileStatus.Authorized
                              this.findMetadata(video)
                              this.findCover(video)
                            }
                          })
                      })
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
                this.currentWidthBreakpoint == "xl" ? "1fr 1fr 1fr 1fr 1fr 1fr 1fr" : "1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr"
              )
            )
          )
        )
      )
      .edgeEffect(EdgeEffect.Spring)
      .expandSafeArea([SafeAreaType.SYSTEM], this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG ? [SafeAreaEdge.BOTTOM] : [])
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
      })
    }
  }

}



@Component
struct VideoRow {

  @Prop
  deleter: VideoDeleter
  @ObjectLink
  video: VideoEntityV2
  @Link
  covers: Record<string, PixelMap>
  @Link
  metadatas: Record<string, media.AVMetadata>

  build() {
    if (this.video.status == FileStatus.Authorized) {
      Row() {
        Button() {
          Column() {
            if (this.covers[this.video.hash] != undefined) {
              Image(this.covers[this.video.hash])
                .width("100%")
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
            if (this.metadatas[this.video.hash] != undefined) {
              Text($r("app.string.duration", `${convertNumberToDurationString(parseInt(this.metadatas[this.video.hash].duration))}`))
                .fontSize(10)
                .fontColor($r("app.color.font_secondary"))
                .margin({
                  left: "8vp",
                  right: "8vp",
                })
            }
            Text(DateUtil.getFormatDateStr(this.video.addedTime))
              .maxLines(1)
              .textOverflow({
                overflow: TextOverflow.Ellipsis
              })
              .fontSize(10)
              .fontColor($r("app.color.font_secondary"))
              .margin({
                left: "8vp",
                right: "8vp",
                bottom: "8vp"
              })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .onClick(() => {
          let context = getContext(this) as common.UIAbilityContext
          let want: Want = {
            bundleName: 'org.rohy.player',
            abilityName: 'VideoAbility',
            parameters: {
              'url': this.video.uri,
              'title': this.video.title,
              'hash': this.video.hash
            }
          }
          context.startAbility(want)
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
              .fontWeight(FontWeight.Medium)
              // .margin(12)
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
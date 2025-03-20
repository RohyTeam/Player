import {
  FileStatus,
  LocalVideoSource,
  Videos,
  VideoSource,
  VideoSourceType,
  WebDAVVideoSource
} from '../../../entity/VideoEntity'
import common from '@ohos.app.ability.common'
import { BreakpointConstants } from '../../../common/constants/BreakpointConstants'
import { VideoDeleter } from './VideoLibraryPage'
import { fileIo, fileShare, hash } from '@kit.CoreFileKit'
import { convertNumberToDurationString } from '../../../util/TimeUtil'
import { Base64Util, FileUtil, StrUtil } from '@pura/harmony-utils'
import { LengthMetrics } from '@kit.ArkUI'
import { DialogHelper } from '@pura/harmony-dialog'
import { VideoLibraryDatabase } from '../../../database/VideoLibraryDatabase'
import { openVideo } from '../../../util/PlayerUtil'
import { showAlert } from '../../../util/AlertUtil'
import { arrayBufferToPixelMap } from '../../../util/ImageUtil'
import { Fonts } from '../../../entity/FontEntity'
import SubtitleManager from 'librohy_subtitle.so'
import { createClientByData, WebDAVClient } from '../../../lib/webdav_client/WebDAVClient'
import { WebDAVs } from '../../../entity/WebDAVEntity'
import { WebDAVDatabase } from '../../../database/WebDAVDatabase'
import { BusinessError } from '@kit.BasicServicesKit'
import { Rlog } from '../../../log/Rlog'

@Component
export struct GridView {
  @Link
  fonts: Fonts
  @Prop
  searching: string
  @ObjectLink
  videos: Videos
  @Prop
  deleter: VideoDeleter
  @Link
  covers: Record<string, PixelMap>
  @Link
  webdavs: WebDAVs
  @Link
  webdavClients: Record<string, WebDAVClient>
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
        ForEach(this.videos, (video: VideoSource) => {
          if (this.searching.length == 0 ||
            video.title.indexOf(this.searching) >= 0 && video.status != FileStatus.Disappear) {
            GridItem() {
              VideoRow({
                fonts: this.fonts,
                deleter: this.deleter,
                covers: this.covers,
                video: video,
                webdavClients: this.webdavClients
              })
                .onAppear(() => {
                  if (video.status == FileStatus.Authorized) {
                    this.convertCover(video)
                  } else if (video.status == FileStatus.None) {
                    this.convertCover(video)
                    if (video.type == VideoSourceType.LOCAL) {
                      fileShare.activatePermission([{
                        uri: video.uri,
                        operationMode: 0b1
                      }])
                        .then(() => {
                          hash.hash(FileUtil.getFilePath(video.uri), "sha256")
                            .then((fileHash) => {
                              if (fileHash != (video as LocalVideoSource).hash) {
                                video.status = FileStatus.Disappear
                                this.deleter.action(video)
                              } else {
                                if (video.length == -1) {
                                  VideoLibraryDatabase.updateVersion3ByHash(
                                    getContext(this),
                                    (video as LocalVideoSource).hash,
                                    video.uri
                                  )
                                    .then(() => {
                                      video.status = FileStatus.Authorized
                                    })
                                } else {
                                  video.status = FileStatus.Authorized
                                }
                              }
                            })
                        })
                        .catch(() => {
                          video.status = FileStatus.Disappear
                          this.deleter.action(video)
                        })
                    } else if (video.type == VideoSourceType.PHOTOS) {
                      // 由于用户无法直接修改视频在相册里的名称（除非删除）所以只验证文件是否存在，而不验证是否对的上哈希值
                      fileIo.open(video.uri)
                        .then((file) => {
                          if (video.length == -1) {
                            VideoLibraryDatabase.updateVersion3ByHash(
                              getContext(this),
                              (video as LocalVideoSource).hash,
                              video.uri
                            )
                              .then(() => {
                                video.status = FileStatus.Authorized
                              })
                          } else {
                            video.status = FileStatus.Authorized
                          }
                        })
                        .catch((err: BusinessError) => {
                          Rlog.error(`video from photos not exists`, {
                            error: err
                          })
                          video.status = FileStatus.Disappear
                          this.deleter.action(video)
                        })
                    } else if (video.type == VideoSourceType.WEBDAV) {
                      let webdavVideo = video as WebDAVVideoSource
                      if (this.webdavClients[webdavVideo.serverUrl] == undefined) {
                        let webdavIndex = this.webdavs.findIndex((auth) => auth.url == webdavVideo.serverUrl)
                        if (webdavIndex < 0) {
                          video.status = FileStatus.NetworkNotAccessible
                          // 网络视频不进行删除处理，因为用户可能处于离线环境
                          return
                        }
                        this.webdavClients[webdavVideo.serverUrl] = createClientByData(this.webdavs[webdavIndex])
                      }
                      let webdavClient = this.webdavClients[webdavVideo.serverUrl]
                      if (webdavClient.getAuthorizationResult() == undefined) {
                        webdavClient.authenticate()
                          .then((result) => {
                            if (result) {
                              video.status = FileStatus.Authorized
                            } else {
                              video.status = FileStatus.NetworkNotAccessible
                              // 网络视频不进行删除处理，因为用户可能处于离线环境
                            }
                          })
                      } else {
                        if (webdavClient.getAuthorizationResult()) {
                          video.status = FileStatus.Authorized
                        } else {
                          video.status = FileStatus.NetworkNotAccessible
                          // 网络视频不进行删除处理，因为用户可能处于离线环境
                        }
                      }
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
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
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

  private convertCover(video: VideoSource) {
    if (this.covers[video.identity()] == undefined) {
      arrayBufferToPixelMap(video.cover)
        .then((pixelMap) => {
          this.covers[video.identity()] = pixelMap
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
  video: VideoSource
  @Link
  covers: Record<string, PixelMap>
  @Link
  webdavClients: Record<string, WebDAVClient>

  build() {
    if (!(this.video.status == FileStatus.Importing ||
      (this.video instanceof WebDAVVideoSource && this.webdavClients[this.video.serverUrl] == undefined))) {
      if (this.video.status == FileStatus.NetworkNotAccessible) {
        Row() {
          Button() {
            Column() {
              Image($r("app.media.network_not_accessible"))
                .width("100%")
                .aspectRatio(4 / 3)
                .borderRadius(10)
              Text($r("app.string.network_not_accessible"))
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
              Text($r("app.string.network_not_accessible"))
                .fontSize(10)
                .fontColor($r("app.color.font_secondary"))
                .margin({
                  left: "8vp",
                  right: "8vp",
                })
              Text($r("app.string.network_not_accessible"))
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
          Button() {
            Column() {
              if (this.covers[this.video.identity()] != undefined) {
                Image(this.covers[this.video.identity()])
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
                Text($r("app.string.played_status_playing",
                  `${Math.ceil(this.video.played / this.video.length * 100)}`))
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
            if (this.video instanceof LocalVideoSource) {
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
                  openVideo(
                    getContext(this) as common.UIAbilityContext,
                    this.video.uri,
                    this.video.title,
                    this.video.identity(),
                    {
                      length: this.video.length,
                      width: this.video.width,
                      height: this.video.height
                    }
                  )
                })
                .catch((err: BusinessError) => {
                  Rlog.fatal("failed to open video", {
                    error: err
                  })
                  this.deleter.action(this.video)
                  showAlert(this.getUIContext(), $r("app.string.file_deleted"),
                    $r("app.string.file_deleted_desc"))
                })
            } else if (this.video instanceof WebDAVVideoSource) {
              let webdavClient = this.webdavClients[this.video.serverUrl]
              if (webdavClient == undefined) {
                return
              }
              webdavClient.authenticateFile(this.video.uri)
                .then((fileResult) => {
                  if (this.video.played >= this.video.length) {
                    AppStorage.setOrCreate("videoPosition", 0)
                  } else {
                    AppStorage.setOrCreate("videoPosition", this.video.played)
                  }
                  openVideo(
                    getContext(this) as common.UIAbilityContext,
                    fileResult.url,
                    this.video.title,
                    this.video.identity(),
                    {
                      length: this.video.length,
                      width: this.video.width,
                      height: this.video.height
                    },
                    fileResult.headers
                  )
                })
            }
          })
          .bindContextMenu(this.contextMenu, ResponseType.LongPress)
          .type(ButtonType.Normal)
          .margin(4)
          .borderRadius(10)
          .backgroundColor($r("app.color.rohy_card"))
        }
        .borderRadius(12)
        .backgroundColor($r("app.color.rohy_card"))
      }
    } else {
      // 目的：让加载中的控件大小和加载后的大小一致，保持 ui 美观性
      Row() {
        Button() {
          Stack() {
            Column() {
              Image($r("app.media.network_not_accessible"))
                .width("100%")
                .aspectRatio(4 / 3)
                .borderRadius(10)
              Text(" ")
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
              Text(" ")
                .fontSize(10)
                .fontColor($r("app.color.font_secondary"))
                .margin({
                  left: "8vp",
                  right: "8vp",
                })
              Text(" ")
                .fontSize(10)
                .fontColor($r("app.color.font_secondary"))
                .margin({
                  left: "8vp",
                  right: "8vp",
                  bottom: "8vp"
                })
            }
            .visibility(Visibility.Hidden)
            .alignItems(HorizontalAlign.Start)

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
          }
        }
        .bindContextMenu(this.contextMenu, ResponseType.LongPress)
        .type(ButtonType.Normal)
        .margin(4)
        .borderRadius(10)
        .backgroundColor($r("app.color.rohy_card"))
      }
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
                  if (this.video instanceof LocalVideoSource) {
                    let hash = StrUtil.unit8ArrayToStr(Base64Util.decodeSync(this.video.identity())).split("|")[1]
                    VideoLibraryDatabase.updateNameByHash(getContext(this), hash, value)
                      .then(() => {
                      })
                  } else if (this.video instanceof WebDAVVideoSource) {
                    let splitData = StrUtil.unit8ArrayToStr(Base64Util.decodeSync(this.video.identity())).split("|")
                    let serverUrl = splitData[0]
                    let location = splitData[1]

                    WebDAVDatabase.updateNameByLocationAndUrl(getContext(this), value, location, serverUrl)
                      .then(() => {
                      })
                  }
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
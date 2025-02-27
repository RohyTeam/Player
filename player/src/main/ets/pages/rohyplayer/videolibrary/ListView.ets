import { FileStatus,
  VideoSourceType,
  Videos,
  VideoSource,
  LocalVideoSource,
  WebDAVVideoSource} from '../../../entity/VideoEntity'
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
import { createClientByData, WebDAVClient } from '../../../lib/webdav_client/WebDAVClient'
import { WebDAVs } from '../../../entity/WebDAVEntity'
import { limitStringLength } from '../../../util/StringUtil'
import { WebDAVDatabase } from '../../../database/WebDAVDatabase'

@Component
export struct ListView {
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
  private scroller = new ListScroller()
  @StorageLink('currentWidthBreakpoint')
  currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;

  build() {
    Column() {
      List({ space: 8, scroller: this.scroller }) {
        ForEach(this.videos, (video: VideoSource) => {
          if (this.searching.length == 0 ||
            video.title.indexOf(this.searching) >= 0 && video.status != FileStatus.Disappear) {
            ListItem() {
              VideoRow({
                fonts: this.fonts,
                covers: this.covers,
                deleter: this.deleter,
                video: video,
                webdavClients: this.webdavClients
              })
            }
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
                    .catch(() => {
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
  swipeToRemoveButton(item: VideoSource) {
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
              if (item instanceof LocalVideoSource) {
                VideoLibraryDatabase.updateNameByHash(getContext(this), item.hash, value)
                  .then(() => {
                  })
              } else if (item instanceof WebDAVVideoSource) {
                WebDAVDatabase.updateNameByLocationAndUrl(getContext(this), value, item.uri, item.serverUrl)
                  .then(() => {
                  })
              }
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
  @ObjectLink
  video: VideoSource
  @Prop
  deleter: VideoDeleter
  @Link
  covers: Record<string, PixelMap>
  @Link
  webdavClients: Record<string, WebDAVClient>
  @StorageLink('currentWidthBreakpoint')
  currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;

  build() {
    if (!(this.video.status == FileStatus.Importing ||
      (this.video instanceof WebDAVVideoSource && this.webdavClients[this.video.serverUrl] == undefined))) {
      if (this.video.status == FileStatus.NetworkNotAccessible) {
        Row() {
          Button() {
            Row() {
              Image($r("app.media.network_not_accessible"))
                .width(80)
                .height(60)
                .margin(8)
                .borderRadius(5)
              Column() {
                Text($r("app.string.network_not_accessible"))
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
                  Text($r("app.string.network_not_accessible"))
                    .fontSize(10)
                    .fontColor($r("app.color.font_secondary"))
                    .margin({
                      bottom: "10vp"
                    })
                  Blank()
                    .layoutWeight(1)
                  Text($r("app.string.network_not_accessible"))
                    .fontSize(10)
                    .fontColor($r("app.color.font_secondary"))
                    .margin({
                      bottom: "10vp",
                      right: "10vp"
                    })
                }
                .width("100%")
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .height("100%")
            }
          }
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
          Button() {
            Row() {
              if (this.covers[this.video.identity()] != undefined) {
                Image(this.covers[this.video.identity()])
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
                    limitStringLength(this.video.identity(), 100),
                    {
                      length: this.video.length,
                      width: this.video.width,
                      height: this.video.height
                    })
                })
                .catch(() => {
                  this.video.status = FileStatus.Disappear
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
                    this.video.uri,
                    this.video.title,
                    limitStringLength(this.video.identity(), 100),
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
          .type(ButtonType.Normal)
          .margin(4)
          .borderRadius(10)
          .backgroundColor($r("app.color.rohy_card"))
        }
        .borderRadius(12)
        .height("84vp")
        .width("90%")
        .backgroundColor($r("app.color.rohy_card"))
      }
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
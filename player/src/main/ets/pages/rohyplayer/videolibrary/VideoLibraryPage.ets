import { LengthMetrics } from '@kit.ArkUI'
import { fileIo, hash, picker } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import {
  FileStatus,
  FileVideoSource,
  LocalVideoSource,
  Videos,
  VideoSource,
  VideoSourceType,
  WebDAVVideoSource
} from '../../../entity/VideoEntity'
import { VideoLibraryDatabase } from '../../../database/VideoLibraryDatabase'
import { ListView } from './ListView'
import { getIcon } from '../../../util/IconUtil'
import { Base64Util, FileUtil, PreferencesUtil, StrUtil } from '@pura/harmony-utils'
import { showAlert } from '../../../util/AlertUtil'
import { GridView } from './GridView'
import { BreakpointConstants } from '../../../common/constants/BreakpointConstants'
import { dataSharePredicates } from '@kit.ArkData'
import { hashByFd } from '../../../util/HashUtil'
import { Fonts } from '../../../entity/FontEntity'
import { WebDAVAuthorization, WebDAVs } from '../../../entity/WebDAVEntity'
import { VirtualFilePicker, VirtualNode } from '../../components/VirtualFilePicker'
import { createClientByData, WebDAVClient } from '../../../lib/webdav_client/WebDAVClient'
import { WebDAVDatabase } from '../../../database/WebDAVDatabase'
import { SettingsSheetView, SettingsSheetViewFunctions } from '../../settings/SettingsSheetView'
import { VideoLibrarySettingsPage } from '../../settings/pages/VideoLibrarySettingsPage'
import { ProgressLoadingOverlay } from '../../components/Overlays'
import { Rlog, RLogger } from '../../../log/Rlog'

export interface VideoDeleter {

  action: (video: VideoSource) => void
  renamer: (video: VideoSource, name: string) => void
  updater: (video: VideoSource, played: number) => void

}

let LOGGER = RLogger.of('VideoLibraryPage')

@Component
export struct VideoLibraryPage {
  @Link
  fonts: Fonts
  @Link
  webdavs: WebDAVs
  @State
  showSettings: boolean = false
  @State
  showPickerSelection: boolean = false
  @State
  private videos: Videos = []
  @State
  private covers: Record<string, PixelMap> = {}
  @State
  private webdavClients: Record<string, WebDAVClient> = {}
  @State
  private loaded: boolean = false
  @State
  private gridOrList: boolean = true // true for List, false for grid
  @State
  private timeOrName: boolean = true // true for Name, false for time
  @State
  private sortReversed: boolean = false
  @State
  searching: string = ""
  @StorageLink(`updateVideoTime`)
  @Watch("videoUpdater")
  toBeUpdatedVideoIdentity: string = ""
  // 这个是导入视频时使用的
  @State
  private videosLoading: number = 1
  @State
  private videosLoaded: number = 0
  private loadingOverlay: CustomDialogController | null = new CustomDialogController({
    builder: ProgressLoadingOverlay({
      loading: this.videosLoading,
      loaded: this.videosLoaded
    }),
    autoCancel: false,
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

  videoUpdater(changedPropertyName: string) {
    LOGGER.debug(`video data is about to be updated`)
    if (this.toBeUpdatedVideoIdentity.startsWith("local:")) {
      LOGGER.debug(`ready to update local video data`)
      let identity = this.toBeUpdatedVideoIdentity.substring(6)
      let fileHash = StrUtil.unit8ArrayToStr(Base64Util.decodeSync(identity)).split("|")[1]
      VideoLibraryDatabase.tryFetchByHash(getContext(this), fileHash)
        .then((updatedVideo) => {
          if (updatedVideo != undefined) {
            LOGGER.debug(`sucessfully fetched updated video data from database`)
            let index = this.videos.findIndex((video) => video instanceof LocalVideoSource && video.hash == fileHash)
            if (index >= 0) {
              LOGGER.debug(`updated video data for "${this.videos[index].title}"`)
              this.videos[index].played = updatedVideo.played
              this.sort()
            } else { // 说明通过别的办法添加了新的视频
              // this.videos.push(VideoEntityV2.fromV1(updatedVideo))
              // TODO: 这个逻辑目前碰不到
              LOGGER.warn(`video to be updated not exists which shouldn't happen`)
              this.sort()
            }
          } else {
            LOGGER.warn(`failed to fetch updated video data from database`)
          }
        })
        .catch((err: BusinessError) => {
          LOGGER.error(`failed to fetch updated video data from database`, {
            error: err
          })
        })
    } else if (this.toBeUpdatedVideoIdentity.startsWith("webdav:")) {
      LOGGER.debug(`ready to update webdav video data`)
      let identity = this.toBeUpdatedVideoIdentity.substring(7)
      let splitData = StrUtil.unit8ArrayToStr(Base64Util.decodeSync(identity)).split("|")
      let serverUrl = splitData[0]
      let location = splitData[1]
      WebDAVDatabase.tryFetchByLocationAndUrl(
        getContext(this),
        location,
        serverUrl
      ).then((updatedVideo) => {
        if (updatedVideo != undefined) {
          LOGGER.debug(`sucessfully fetched updated video data from database`)
          let index =
            this.videos.findIndex((video) => video instanceof WebDAVVideoSource && video.identity() == identity)
          if (index >= 0) {
            LOGGER.debug(`updated video data for "${this.videos[index].title}"`)
            this.videos[index].played = updatedVideo.played
            // 因为获取视频元数据的限制， webdav 视频可能会在第一次播放后才更新元数据，所以这里同时也更新一下元数据
            this.videos[index].length = updatedVideo.length
            this.videos[index].width = updatedVideo.width
            this.videos[index].height = updatedVideo.height
            this.sort()
          } else {
            // FIXME: 理论上不会出现
            LOGGER.warn(`video to be updated not exists which shouldn't happen`)
            this.sort()
          }
        } else {
          LOGGER.warn(`failed to fetch updated video data from database`)
        }
      })
        .catch((err: BusinessError) => {
          LOGGER.error(`failed to fetch updated video data from database`, {
            error: err
          })
        })
    }
  }

  @Builder
  browseMenus() {
    Menu() {
      MenuItemGroup() {
        MenuItem() {
          Row() {
            Text($r("app.string.videolibrary_view_mode_grid"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("96vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(!this.gridOrList ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.gridOrList = false
          PreferencesUtil.putSync("gridOrList", false)

          LOGGER.debug(`changing video library view to "grid" view`)
        })
        .margin({
          left: 4,
          right: 4,
          top: 4
        })

        MenuItem() {
          Row() {
            Text($r("app.string.videolibrary_view_mode_list"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("96vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.gridOrList ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          this.gridOrList = true
          PreferencesUtil.putSync("gridOrList", true)

          LOGGER.debug(`changing video library view to "list" view`)
        })
        .margin({
          left: 4,
          right: 4
        })

        MenuItem()
          .margin({
            bottom: "8vp"
          })
      }

      MenuItemGroup() {
        MenuItem()
        MenuItem() {
          Row() {
            Text($r("app.string.videolibrary_view_sort_name"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("36vp")
            SymbolGlyph(this.sortReversed ? $r("sys.symbol.text_and_arrow_down") : $r("sys.symbol.text_and_arrow_up"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.timeOrName ? Visibility.Visible : Visibility.Hidden)
              .fontSize(24)
            Blank()
              .width("36vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(this.timeOrName ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          if (this.timeOrName) {
            this.sortReversed = !this.sortReversed
          } else {
            this.sortReversed = false
            this.timeOrName = true
          }
          this.sort()
        })
        .margin({
          left: 4,
          right: 4
        })

        MenuItem() {
          Row() {
            Text($r("app.string.videolibrary_view_sort_time"))
              .fontWeight(FontWeight.Medium)
              .margin(12)
            Blank()
              .width("36vp")
            SymbolGlyph(this.sortReversed ? $r("sys.symbol.text_and_arrow_down") : $r("sys.symbol.text_and_arrow_up"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(!this.timeOrName ? Visibility.Visible : Visibility.Hidden)
              .fontSize(24)
            Blank()
              .width("36vp")
            SymbolGlyph($r("sys.symbol.checkmark"))
              .fontColor([$r("app.color.icon_primary")])
              .visibility(!this.timeOrName ? Visibility.Visible : Visibility.Hidden)
              .margin(12)
              .fontSize(24)
          }
          .onClick(() => {
            if (!this.timeOrName) {
              this.sortReversed = !this.sortReversed
            } else {
              this.sortReversed = false
              this.timeOrName = false
            }
            this.sort()
          })
          .alignItems(VerticalAlign.Center)
        }
        .margin({
          bottom: 4,
          left: 4,
          right: 4
        })
      }
    }
    .menuItemDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
    })
    .menuItemGroupDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(8),
      startMargin: LengthMetrics.vp(0),
      endMargin: LengthMetrics.vp(0)
    })
    .padding(0)
  }

  @Builder
  menus() {
    Row() {
      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.plus"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        right: 12
      })
      .width(40)
      .height(40)
      .onClick(() => {
        this.showPickerSelection = true
        this.showSettings = false
      })
      .bindSheet(
        $$this.showPickerSelection,
        this.pickerSelection(),
        {
          height: SheetSize.FIT_CONTENT,
          showClose: false,
          shadow: ShadowStyle.OUTER_DEFAULT_MD,
          enableOutsideInteractive: false,
          shouldDismiss: (sheetDismiss) => {
            sheetDismiss.dismiss()
            this.showPickerSelection = false
          },
          onWillDismiss: () => {
            this.showPickerSelection = false
          },
          backgroundColor: $r("app.color.rohy_settings_background")
        }
      )
      .backgroundColor($r("app.color.comp_background_tertiary"))

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.square_grid_2x2"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        right: 12
      })
      .width(40)
      .height(40)
      .bindMenu(this.browseMenus,
        { backgroundColor: $r("app.color.menus_background"), backgroundBlurStyle: BlurStyle.NONE })
      .backgroundColor($r("app.color.comp_background_tertiary"))

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.gearshape"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        right: 12
      })
      .width(40)
      .height(40)
      .onClick(() => {
        this.showSettings = true
        this.showPickerSelection = false
      })
      .bindSheet(
        $$this.showSettings,
        this.settings(),
        {
          height: SheetSize.LARGE,
          showClose: false,
          shadow: ShadowStyle.OUTER_DEFAULT_MD,
          enableOutsideInteractive: false,
          shouldDismiss: (sheetDismiss) => {
            sheetDismiss.dismiss()
            this.showSettings = false
          },
          onWillDismiss: () => {
            this.showSettings = false
          },
          backgroundColor: $r("app.color.rohy_settings_background")
        }
      )
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .alignItems(VerticalAlign.Center)
    .height("100%")
  }

  @Builder
  private titleBar(title: ResourceStr) {
    Column() {
      Row() {
        Text(title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.font_primary"))
          .margin(16)
        Blank()
          .layoutWeight(1)
        if (this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG) {
          Search({
            placeholder: $r("app.string.search")
          })
            .width("50%")
            .margin({
              left: 16,
              right: 12,
            })
            .height(40)
            .onChange((value) => {
              this.searching = value
            })
        }
        this.menus()
      }
      .height("56vp")
      .width("100%")
    }
    .height("56vp")
    .width("100%")
  }

  @StorageLink('currentWidthBreakpoint')
  currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;

  build() {
    Column() {
      this.titleBar($r("app.string.home_tab_video"))
      Column() {
        if (this.currentWidthBreakpoint !== BreakpointConstants.BREAKPOINT_LG) {
          Search({
            placeholder: $r("app.string.search")
          })
            .width("90%")
            .height(40)
            .onChange((value) => {
              this.searching = value
            })
        }
        if (!this.loaded) {
          Column() {
            Blank()
              .layoutWeight(2)
            LoadingProgress()
              .enableLoading(true)
              .color($r("app.color.icon_secondary"))
              .width(64)
              .height(64)
            Blank()
              .layoutWeight(3)
          }
          .width("100%")
          .height("100%")
        } else {
          Column() {
            if (this.gridOrList) {
              ListView({
                fonts: this.fonts,
                searching: this.searching,
                videos: this.videos,
                covers: this.covers,
                webdavs: this.webdavs,
                webdavClients: this.webdavClients,
                deleter: {
                  action: (video) => {
                    if (video.type == VideoSourceType.LOCAL || video.type == VideoSourceType.PHOTOS) {
                      let localVideo = video as LocalVideoSource
                      VideoLibraryDatabase.deleteByHash(getContext(this), video.uri, localVideo.hash)
                        .then(() => {
                          video.status = FileStatus.Disappear
                          // 不从 videos 里去掉这个实体了，不知道为什么总是删错，直接用 Disappear 状态停止渲染
                          this.sort()
                        })
                    } else if (video.type == VideoSourceType.WEBDAV) {
                      let webdavVideo = video as WebDAVVideoSource
                      WebDAVDatabase.deleteVideoByLocationAndUrl(getContext(this), webdavVideo.uri,
                        webdavVideo.serverUrl)
                        .then(() => {
                          video.status = FileStatus.Disappear
                          this.sort()
                        })
                    }
                  },
                  renamer: (video, name) => {
                    video.title = name
                    this.sort()
                  },
                  updater: (video, played) => {
                    if (video.type == VideoSourceType.LOCAL || video.type == VideoSourceType.PHOTOS) {
                      let localVideo = video as LocalVideoSource
                      VideoLibraryDatabase.updatePlayedByHash(getContext(this), localVideo.hash, played)
                        .then(() => {
                          video.played = played
                          this.sort()
                        })
                    }
                  }
                },
              })
            } else {
              GridView({
                fonts: this.fonts,
                searching: this.searching,
                videos: this.videos,
                covers: this.covers,
                webdavs: this.webdavs,
                webdavClients: this.webdavClients,
                deleter: {
                  action: (video) => {
                    if (video.type == VideoSourceType.LOCAL || video.type == VideoSourceType.PHOTOS) {
                      let localVideo = video as LocalVideoSource
                      VideoLibraryDatabase.deleteByHash(getContext(this), video.uri, localVideo.hash)
                        .then(() => {
                          video.status = FileStatus.Disappear
                          let index = this.videos.indexOf(video)
                          this.videos.splice(index, 1)
                          this.sort()
                        })
                    } else if (video.type == VideoSourceType.WEBDAV) {
                      let webdavVideo = video as WebDAVVideoSource
                      WebDAVDatabase.deleteVideoByLocationAndUrl(getContext(this), webdavVideo.uri,
                        webdavVideo.serverUrl)
                        .then(() => {
                          video.status = FileStatus.Disappear
                          let index = this.videos.indexOf(video)
                          this.videos.splice(index, 1)
                          this.sort()
                        })
                    }
                  },
                  renamer: (video, name) => {
                    video.title = name
                    this.sort()
                  },
                  updater: (video, played) => {
                    if (video.type == VideoSourceType.LOCAL || video.type == VideoSourceType.PHOTOS) {
                      let localVideo = video as LocalVideoSource
                      VideoLibraryDatabase.updatePlayedByHash(getContext(this), localVideo.hash, played)
                        .then(() => {
                          video.played = played
                          this.sort()
                        })
                    }
                  }
                },
              })
            }
          }
          .width("100%")
          .layoutWeight(1)
        }
      }
      .width("100%")
      .layoutWeight(1)
    }
    .onAppear(() => {
      this.gridOrList = PreferencesUtil.getSync("gridOrList", true) as boolean
      VideoLibraryDatabase.unsafeList(getContext(this)).then((videos) => {
        console.error(`${videos.length} videos loaded`)
        this.videos.push(...videos)
        this.loaded = true
      })
      WebDAVDatabase.unsafeListVideos(getContext(this))
        .then((videos) => {
          this.videos.push(...videos)
        })
    })
    .backgroundColor($r("app.color.comp_background_focus"))
    .height("100%")
    .width("100%")
  }

  @Builder
  pickerSelectionTitle() {
    Row() {
      Text($r("app.string.choose_picker"))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.font_primary"))
        .margin(16)
      Blank()
        .layoutWeight(1)

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.xmark"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .onClick(() => {
        this.showPickerSelection = false
      })
      .align(Alignment.Center)
      .margin({
        right: 12
      })
      .width(40)
      .height(40)
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .margin({
      left: 12,
      right: 12,
      top: 12
    })
    .backgroundColor($r("app.color.rohy_settings_background"))
  }

  @Builder
  pickerSelection() {
    Column() {
      this.pickerSelectionTitle()
      Blank()
        .height(12)
        .width("100%")
      List({ space: 12 }) {
        ListItem() {
          Row() {
            Column() {
              Row() {
                Button() {
                  Row() {
                    Image(getIcon($r("app.media.filemanager_icon")))
                      .width("48vp")
                      .height("48vp")
                      .margin(12)
                    Text($r("app.string.filemanager"))
                      .fontColor($r("app.color.font_primary"))
                    Blank()
                      .layoutWeight(1)
                  }
                  .alignItems(VerticalAlign.Center)
                }
                .onClick(() => {
                  this.showPickerSelection = false
                  this.showFileManagerPicker()
                })
                .width("100%")
                .height("100%")
                .borderRadius(10)
                .type(ButtonType.Normal)
                .backgroundColor($r("app.color.rohy_settings_card"))
              }
              .height("64vp")
              .width("100%")

              Divider()
                .margin({
                  left: 72,
                  right: 12
                })
              Row() {
                Button() {
                  Row() {
                    Image(getIcon($r("app.media.photos_icon")))
                      .width("48vp")
                      .height("48vp")
                      .margin(12)
                      .border({
                        width: 1,
                        radius: 12,
                        color: $r("app.color.icon_fourth")
                      })
                    Text($r("app.string.photos"))
                      .fontColor($r("app.color.font_primary"))
                    Blank()
                      .layoutWeight(1)
                  }
                  .alignItems(VerticalAlign.Center)
                }
                .onClick(() => {
                  this.showPickerSelection = false
                  this.showPhotosPicker()
                })
                .width("100%")
                .height("100%")
                .borderRadius(10)
                .type(ButtonType.Normal)
                .backgroundColor($r("app.color.rohy_settings_card"))
              }
              .height("64vp")
              .width("100%")

              ForEach(this.webdavs, (webdav: WebDAVAuthorization) => {
                Divider()
                  .margin({
                    left: 72,
                    right: 12
                  })
                WebDAVPickerRow({
                  webdav: webdav,
                  videos: this.videos,
                  functions: {
                    clear: () => {
                      this.showPickerSelection = false
                    }
                  }
                })
              })
            }
          }
          .padding(4)
          .borderRadius(12)
          .backgroundColor($r("app.color.rohy_settings_card"))
          .width("90%")
        }
        .width("100%")
      }
      .scrollBar(BarState.Off)
      .backgroundColor($r("app.color.rohy_settings_background"))
      .width("100%")

      Blank()
        .height("28vp")
        .width("100%")
    }
    .backgroundColor($r("app.color.rohy_settings_background"))
    .width("100%")
  }

  @Builder
  settings() {
    SettingsSheetView({
      title: $r("app.string.settings"),
      functions: {
        onClose: () => {
          this.showSettings = false
        }
      },
      mainView: wrapBuilder(settingsContent)
    })
  }

  private showPhotosPicker() {
    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.maxSelectNumber = 10; // 太多了处理不过来
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE
    photoSelectOptions.isPhotoTakingSupported = false // 临时拍一段视频导入进来？谁会这么干。。。

    photoPicker.select(photoSelectOptions)
      .then(async (photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
        if (photoSelectResult.photoUris.length == 0) {
          return
        }
        this.videosLoading = photoSelectResult.photoUris.length
        this.videosLoaded = 0
        this.loadingOverlay?.open()

        let accessor = photoAccessHelper.getPhotoAccessHelper(getContext(this))

        // FIXME 重复文件不会自动关闭加载窗口
        let duplicated = false
        for (let photoUri of photoSelectResult.photoUris) {
          let photoFile = fileIo.openSync(photoUri)
          let pre1 = await hashByFd(photoFile.fd, "sha256")
          let pre2 = await hashByFd(photoFile.fd, "sha256")
          // IMPORTANT: 上面这两行并非无意义操作，对于图库的的文件进行哈希校验存在误差，一般第三次之后的值不会有问题
          let photoHash = await hashByFd(photoFile.fd, "sha256")
          if (this.videos.findIndex((video) => video instanceof LocalVideoSource && video.hash == photoHash) >= 0) {
            duplicated = true
          } else {
            let predicates = new dataSharePredicates.DataSharePredicates()
            predicates.equalTo("uri", photoUri)
            accessor.getAssets({
              fetchColumns: [photoAccessHelper.PhotoKeys.TITLE],
              predicates: predicates
            })
              .then((fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset>) => {
                if (fetchResult.getCount() > 0) {
                  fetchResult.getFirstObject()
                    .then((photoAsset: photoAccessHelper.PhotoAsset) => {
                      VideoLibraryDatabase.addFromPhotos(getContext(this), photoUri, photoAsset.displayName, photoHash)
                        .then((video) => {
                          video.status = FileStatus.Authorized
                          this.videos.push(video)
                          this.videosLoaded += 1
                          if (this.videosLoaded >= this.videosLoading) {
                            this.loadingOverlay?.close()
                          }
                        })
                    })
                }
              })
          }
        }

        if (duplicated) {
          showAlert(this.getUIContext(), $r("app.string.duplicated_imports"),
            $r("app.string.duplicated_imports_desc"))
        }
      })
  }

  private showFileManagerPicker() {
    Rlog.debug("start: invoke of VideoLibraryPage#showFileManagerPicker function")

    let documentViewPicker = new picker.DocumentViewPicker(this.getUIContext().getHostContext()!);
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 10; // 太多了处理不过来
    documentSelectOptions.fileSuffixFilters = [
      'mp4 视频文件|.mp4',
      'mkv 视频文件|.mkv',
      'mov 视频文件|.mov'
    ];

    documentViewPicker.select(documentSelectOptions)
      .then(async (documentSelectResult: Array<string>) => {
        if (documentSelectResult.length == 0) {
          Rlog.debug(`no file selected`)
          Rlog.debug("end: invoke of VideoLibraryPage#showFileManagerPicker function")
          return
        }

        this.videosLoading = documentSelectResult.length
        this.videosLoaded = 0
        this.loadingOverlay?.open()

        // FIXME 重复文件不会自动关闭加载窗口
        let duplicated = false
        let unsupported = false
        for (let fileUrl of documentSelectResult) {
          if (!fileUrl.startsWith("file://")) {
            unsupported = true
            continue
          }
          if (fileUrl.startsWith("file://com.huawei.hmos.filemanager")) { // 说明是云空间的文件，被文件管理缓存到文件管理的沙箱中了
            unsupported = true
            continue
          }
          LOGGER.debug(`importing file: ${FileUtil.getFileName(fileUrl)}`)
          let hashValue = await hash.hash(FileUtil.getFilePath(fileUrl), "sha256")
          if (this.videos.findIndex((video) => video instanceof LocalVideoSource && video.hash == hashValue) >= 0) {
            duplicated = true
          } else {
            let videoSource = new FileVideoSource(
              "",
              "",
              0,
              -1,
              -1,
              -1,
              -1,
              new ArrayBuffer(0),
              ""
            )
            videoSource.status = FileStatus.Importing
            this.videos.push(videoSource)
            VideoLibraryDatabase.addFromLocalFile(getContext(this), fileUrl)
              .then((video) => {
                videoSource.uri = video.uri
                videoSource.title = video.title
                videoSource.hash = video.hash
                videoSource.addedTime = video.addedTime
                videoSource.length = video.length
                videoSource.width = video.width
                videoSource.height = video.height
                videoSource.cover = video.cover
                videoSource.status = FileStatus.Authorized
                this.sort()
                this.videosLoaded += 1
                if (this.videosLoaded >= this.videosLoading) {
                  this.loadingOverlay?.close()
                }
              })
          }
        }
        Rlog.debug(`selected ${documentSelectResult.length} file${documentSelectResult.length > 1 ? "s" :
          ""} to import`)

        if (duplicated) {
          Rlog.debug("duplicated file found")
          showAlert(this.getUIContext(), $r("app.string.duplicated_imports"), $r("app.string.duplicated_imports_desc"),
            () => {
              if (unsupported) {
                Rlog.debug("unsupported file found")
                showAlert(this.getUIContext(), $r("app.string.import_unsupported_source"),
                  $r("app.string.import_unsupported_source_desc"))
              }
            })
        } else if (unsupported) {
          Rlog.debug("unsupported file found")
          showAlert(this.getUIContext(), $r("app.string.import_unsupported_source"),
            $r("app.string.import_unsupported_source_desc"))
        }
        Rlog.debug("end: invoke of VideoLibraryPage#showFileManagerPicker function")
      })
      .catch((err: BusinessError) => {
        Rlog.error(`failed to use picker`, {
          error: err
        })
        Rlog.debug("end: invoke of VideoLibraryPage#showFileManagerPicker function")
      })
  }

  private sort() {
    if (this.timeOrName) {
      if (this.sortReversed) {
        this.videos.sort((a, b) => {
          return -a.title.localeCompare(b.title)
        })
      } else {
        this.videos.sort((a, b) => {
          return a.title.localeCompare(b.title)
        })
      }
    } else {
      if (this.sortReversed) {
        this.videos.sort((a, b) => {
          return a.addedTime > b.addedTime ? -1 : a.addedTime == b.addedTime ? 0 : 1
        })
      } else {
        this.videos.sort((a, b) => {
          return a.addedTime < b.addedTime ? -1 : a.addedTime == b.addedTime ? 0 : 1
        })
      }
    }
  }
}

interface WebDAVPickerRowFunctions {

  clear: () => void

}

@Component
struct WebDAVPickerRow {
  @Prop
  @Require
  webdav: WebDAVAuthorization
  @Prop
  @Require
  functions: WebDAVPickerRowFunctions
  @Link
  videos: Videos
  @State
  private webdavClient: WebDAVClient | undefined = undefined
  @State
  private showVirtualPicker: boolean = false

  aboutToAppear(): void {
    this.webdavClient = createClientByData(this.webdav)
  }

  build() {
    Row() {
      Button() {
        Row() {
          Image(getIcon($r("app.media.webdav_icon")))
            .width("48vp")
            .height("48vp")
            .margin(12)
            .border({
              width: 1,
              radius: 12,
              color: $r("app.color.icon_fourth")
            })
          Text(this.webdav.displayName)
            .fontColor($r("app.color.font_primary"))
          Blank()
            .layoutWeight(1)
        }
        .alignItems(VerticalAlign.Center)
      }
      .bindSheet(
        $$this.showVirtualPicker,
        this.virtualFilePicker,
        {
          showClose: false,
          preferType: SheetType.CENTER,
          shadow: ShadowStyle.OUTER_DEFAULT_MD,
          enableOutsideInteractive: false,
          shouldDismiss: (sheetDismiss) => {
            sheetDismiss.dismiss()
            console.error(`virtual picker should dismiss triggered`)
            this.showVirtualPicker = false
            this.functions.clear()
          },
          onWillDismiss: () => {
            console.error(`virtual picker will dismiss triggered`)
            this.showVirtualPicker = false
            this.functions.clear()
          },
          backgroundColor: $r("app.color.rohy_settings_background")
        }
      )
      .onClick(() => {
        this.showVirtualPicker = true
      })
      .width("100%")
      .height("100%")
      .borderRadius(10)
      .type(ButtonType.Normal)
      .backgroundColor($r("app.color.rohy_settings_card"))
    }
    .height("64vp")
    .width("100%")
  }

  @Builder
  virtualFilePicker() {
    VirtualFilePicker({
      title: this.webdav.displayName,
      fileSystem: {
        listFiles: (path: string) => {
          return new Promise((resultReturner) => {
            this.webdavClient!.authenticate()
              .then((result) => {
                this.webdavClient!.listDirectory(path)
                  .then((webdavFiles) => {
                    let files: VirtualNode[] = []
                    for (let webdavFile of webdavFiles) {
                      files.push({
                        displayName: webdavFile.displayName,
                        name: decodeURI(webdavFile.path),
                        size: webdavFile.size,
                        isDirectory: webdavFile.isDirectory
                      })
                    }
                    resultReturner(files)
                  })
              })
          })
        },
        visibleFilter: (node: VirtualNode) => {
          if (node.isDirectory) {
            return true
          }
          return node.name.endsWith(".mp4") || node.name.endsWith(".mkv") || node.name.endsWith(".mov")
        },
        onFileSelected: (path: string, node: VirtualNode) => {
          this.showVirtualPicker = false
          console.error(`which file was selected: ${path}`)
          WebDAVDatabase.addVideo(getContext(this), this.webdavClient!, this.webdav.url, path, node)
            .then((video) => {
              if (this.videos.findIndex((savedVideo) => savedVideo instanceof WebDAVVideoSource &&
                savedVideo.serverUrl == video.serverUrl &&
                savedVideo.uri == video.uri)) {
                showAlert(this.getUIContext(), $r("app.string.duplicated_imports"),
                  $r("app.string.duplicated_imports_desc"))
              } else {
                this.videos.push(video)
              }
            })
        }
      },
      show: this.showVirtualPicker
    })
  }
}

@Builder
function settingsContent(settingsPageController: NavPathStack, functions: SettingsSheetViewFunctions) {
  VideoLibrarySettingsPage({
    functions: functions
  })
}
import { ComposeTitleBar, LengthMetrics, promptAction, SymbolGlyphModifier } from '@kit.ArkUI'
import { hash, picker } from '@kit.CoreFileKit'
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { VideoEntityV2, VideoEntityV2Array } from '../../../entity/VideoEntity'
import { VideoLibraryDatabase } from '../../../database/VideoLibraryDatabase'
import { ListView } from './ListView'
import { getIcon } from '../../../util/IconUtil'
import { FileUtil, PreferencesUtil } from '@pura/harmony-utils'
import { StringArray } from '../../../entity/Arrays'
import { showAlert } from '../../../util/AlertUtil'
import { GridView } from './GridView'
import { media } from '@kit.MediaKit'
import { CommonConstants } from '../../../common/constants/CommonConstants'
import { BreakpointConstants } from '../../../common/constants/BreakpointConstants'

export interface VideoDeleter {

  action: (video: VideoEntityV2) => void
  renamer: (video: VideoEntityV2, name: string) => void

}

@Component
export struct VideoLibraryPage {
  @State
  showSettings: boolean = false
  @State
  showPickerSelection: boolean = false
  @State
  private videos: VideoEntityV2Array = []
  @State
  private covers: Record<string, PixelMap> = {}
  @State
  private metadatas: Record<string, media.AVMetadata> = {}
  @State
  private loaded: boolean = false
  @State
  private hashes: StringArray = []
  @State
  private gridOrList: boolean = true // true for List, false for grid
  @State
  private timeOrName: boolean = true // true for Name, false for time
  @State
  private sortReversed: boolean = false

  @State
  searching: string = ""

  @Builder
  browseMenus() {
    Menu() {
      MenuItemGroup() {
        MenuItem({
          content: $r("app.string.videolibrary_view_mode_grid"),
          symbolEndIcon: !this.gridOrList ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.gridOrList = false
            PreferencesUtil.putSync("gridOrList", false)
          })
          .margin({
            top: 4,
            left: 4,
            right: 4
          })
        MenuItem({
          content: $r("app.string.videolibrary_view_mode_list"),
          symbolEndIcon: this.gridOrList ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.gridOrList = true
            PreferencesUtil.putSync("gridOrList", true)
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
          showClose: true,
          title: {
            title: $r("app.string.choose_picker")
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
      .bindMenu(this.browseMenus)
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
          showClose: true,
          title: {
            title: $r("app.string.settings")
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
              right: 16,
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
                searching: this.searching,
                videos: this.videos,
                covers: this.covers,
                metadatas: this.metadatas,
                deleter: {
                  action: (video) => {
                    VideoLibraryDatabase.deleteByHash(getContext(this), video.hash)
                      .then(() => {
                        let index = this.videos.indexOf(video)
                        let hashIndex = this.hashes.indexOf(video.hash)
                        this.videos.splice(index, 1)
                        this.hashes.splice(hashIndex, 1)
                        this.sort()
                      })
                  },
                  renamer: (video, name) => {
                    video.title = name
                    this.sort()
                  }
                },
              })
            } else {
              GridView({
                searching: this.searching,
                videos: this.videos,
                covers: this.covers,
                metadatas: this.metadatas,
                deleter: {
                  action: (video) => {
                    VideoLibraryDatabase.deleteByHash(getContext(this), video.hash)
                      .then(() => {
                        let index = this.videos.indexOf(video)
                        let hashIndex = this.hashes.indexOf(video.hash)
                        this.videos.splice(index, 1)
                        this.hashes.splice(hashIndex, 1)
                        this.sort()
                      })
                  },
                  renamer: (video, name) => {
                    video.title = name
                    this.sort()
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
        this.videos.push(...videos.map((v1) => VideoEntityV2.fromV1(v1)))
        this.hashes.push(...videos.map((v1) => v1.hash))
        this.loaded = true
      })
    })
    .backgroundColor($r("app.color.comp_background_focus"))
    .height("100%")
    .width("100%")
  }

  @Builder
  pickerSelection() {
    Column() {
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
                  // this.showPhotosPicker()

                  promptAction.showToast({
                    'message': "由于暂时无法持久化访问媒体库的视频，所以此功能暂时无法使用"
                  })
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
    Column() {
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
                    SymbolGlyph($r("sys.symbol.questionmark_circle"))
                      .fontColor([$r("app.color.icon_primary")])
                      .fontSize(24)
                      .margin(12)
                    Text($r("app.string.questions"))
                      .fontColor($r("app.color.font_primary"))
                    Blank()
                      .layoutWeight(1)
                  }
                  .alignItems(VerticalAlign.Center)
                }
                .onClick(() => {
                  promptAction.showToast({
                    'message': $r("app.string.coming_soon")
                  })
                })
                .width("100%")
                .height("100%")
                .borderRadius(10)
                .type(ButtonType.Normal)
                .backgroundColor($r("app.color.rohy_settings_card"))
              }
              .height("48vp")
              .width("100%")

              Divider()
                .margin({
                  left: 48,
                  right: 12
                })
              Row() {
                Button() {
                  Row() {
                    SymbolGlyph($r("sys.symbol.info_circle"))
                      .fontColor([$r("app.color.icon_primary")])
                      .fontSize(24)
                      .margin(12)
                    Text($r("app.string.about"))
                      .fontColor($r("app.color.font_primary"))
                    Blank()
                      .layoutWeight(1)
                  }
                  .alignItems(VerticalAlign.Center)
                }
                .onClick(() => {
                  promptAction.showToast({
                    'message': $r("app.string.coming_soon")
                  })
                })
                .width("100%")
                .height("100%")
                .borderRadius(10)
                .type(ButtonType.Normal)
                .backgroundColor($r("app.color.rohy_settings_card"))
              }
              .height("48vp")
              .width("100%")
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
      .height("100%")
      .width("100%")
    }
    .backgroundColor($r("app.color.rohy_settings_background"))
    .height("100%")
    .width("100%")
  }

  private showPhotosPicker() {
    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.maxSelectNumber = 10; // 太多了处理不过来
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE
    photoSelectOptions.isPhotoTakingSupported = false // 临时拍一段视频导入进来？谁会这么干。。。

    photoPicker.select(photoSelectOptions)
      .then((photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
        if (photoSelectResult.photoUris.length == 0) {
          return
        }
        let accessor = photoAccessHelper.getPhotoAccessHelper(getContext(this))
        for (let photoUri of photoSelectResult.photoUris) {
          VideoLibraryDatabase.add(getContext(this), photoUri)
            .then((video) => {
              this.videos.push(VideoEntityV2.fromV1(video))
              this.hashes.push(video.hash)
            })
          /*let predicates = new dataSharePredicates.DataSharePredicates()
          predicates.equalTo("uri", photoUri)
          accessor.getAssets({
            fetchColumns: [photoAccessHelper.PhotoKeys.URI, photoAccessHelper.PhotoKeys.WIDTH,
              photoAccessHelper.PhotoKeys.HEIGHT, photoAccessHelper.PhotoKeys.TITLE,
              photoAccessHelper.PhotoKeys.DURATION],
            predicates: predicates
          })
            .then((fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset>) => {
              if (fetchResult.getCount() > 0) {
                fetchResult.getAllObjects()
                  .then((assets: Array<photoAccessHelper.PhotoAsset>) => {
                    for (let asset of assets) {
                      // todo: 处理
                      console.error(asset.uri)
                    }
                  })
              }
            })*/
        }
      })
  }

  private showFileManagerPicker() {
    let documentViewPicker = new picker.DocumentViewPicker(this.getUIContext().getHostContext()!);
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 10; // 太多了处理不过来
    documentSelectOptions.fileSuffixFilters = ['mp4 视频文件|.mp4', 'mkv 视频文件|.mkv'];

    documentViewPicker.select(documentSelectOptions)
      .then(async (documentSelectResult: Array<string>) => {
        if (documentSelectResult.length == 0) {
          return
        }

        let duplicated = false
        for (let fileUrl of documentSelectResult) {
          let hashValue = await hash.hash(FileUtil.getFilePath(fileUrl), "sha256")
          if (this.hashes.indexOf(hashValue) >= 0) {
            duplicated = true
          } else {
            VideoLibraryDatabase.add(getContext(this), fileUrl)
              .then((video) => {
                this.videos.push(VideoEntityV2.fromV1(video))
                this.hashes.push(video.hash)
              })
          }
        }

        if (duplicated) {
          showAlert(this.getUIContext(), $r("app.string.duplicated_imports"), $r("app.string.duplicated_imports_desc"))
        }
      }).catch((err: BusinessError) => {
        console.error(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
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

import { LengthMetrics, promptAction, SymbolGlyphModifier } from '@kit.ArkUI'
import { fileIo, hash, picker } from '@kit.CoreFileKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { FileStatus, VideoEntityV2, VideoEntityV2Array } from '../../../entity/VideoEntity'
import { VideoLibraryDatabase } from '../../../database/VideoLibraryDatabase'
import { ListView } from './ListView'
import { getIcon } from '../../../util/IconUtil'
import { FileUtil, PreferencesUtil } from '@pura/harmony-utils'
import { StringArray } from '../../../entity/Arrays'
import { showAlert } from '../../../util/AlertUtil'
import { GridView } from './GridView'
import { media } from '@kit.MediaKit'
import { BreakpointConstants } from '../../../common/constants/BreakpointConstants'
import { dataSharePredicates } from '@kit.ArkData'
import { hashByFd } from '../../../util/HashUtil'
import { SettingsDivider, SettingsGroup, SettingsPage, SettingsRow,
  SettingsSelection,
  SettingsSwitch } from '../../components/SettingsPage'
import { checkPermissionGrant, requestPermissionsFromUser } from '../../../util/PermissionUtils'
import { abilityAccessCtrl, common } from '@kit.AbilityKit'

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
          showClose: false,
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
  pickerSelectionTitle() {
    Row(){
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

  @State
  settings$continuation: boolean = false
  @StorageLink('appColorMode')
  colorMode: string = "system";
  colorModes: string[] = ["system", "light", "dark"];

  @Builder
  settingsTitle() {
    Row() {
      Text($r("app.string.settings"))
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
        this.showSettings = false
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
  settings() {
    Column() {
      this.settingsTitle()
      Blank()
        .height(12)
        .width("100%")
      SettingsPage() {
        SettingsGroup() {
          SettingsSelection({
            settingsTitle: $r("app.string.color_mode"),
            choices: [
              {
                title: $r("app.string.color_mode_system"),
                onSwitch: () => {
                  animateTo({
                    duration: 300,
                    curve: Curve.Linear,
                    playMode: PlayMode.Normal
                  }, () => {
                    AppStorage.setOrCreate("appColorMode", "system")
                  })
                  PreferencesUtil.putSync("colorMode", "system")
                }
              },
              {
                title: $r("app.string.color_mode_light"),
                onSwitch: () => {
                  animateTo({
                    duration: 300,
                    curve: Curve.Linear,
                    playMode: PlayMode.Normal
                  }, () => {
                    AppStorage.setOrCreate("appColorMode", "light")
                  })
                  PreferencesUtil.putSync("colorMode", "light")
                }
              },
              {
                title: $r("app.string.color_mode_dark"),
                onSwitch: () => {
                  animateTo({
                    duration: 300,
                    curve: Curve.Linear,
                    playMode: PlayMode.Normal
                  }, () => {
                    AppStorage.setOrCreate("appColorMode", "dark")
                  })
                  PreferencesUtil.putSync("colorMode", "dark")
                }
              }
            ],
            selectedButtons: [this.colorModes.indexOf(this.colorMode)]
          })
        }
        SettingsGroup() {
          SettingsSwitch({
            settingsTitle: $r("app.string.settings_continuation"),
            switchValue: this.settings$continuation,
            switchEvent: {
              action: (value: boolean) => {
                if (this.settings$continuation) {
                  // 如果开关是开的我就默认用户有权限了
                  PreferencesUtil.putSync("continuation", false)
                  this.settings$continuation = false
                } else {
                  requestPermissionsFromUser(getContext(this) as common.UIAbilityContext, "ohos.permission.DISTRIBUTED_DATASYNC")
                    .then((value: boolean) => {
                      if (value) {
                        PreferencesUtil.putSync("continuation", true)
                        this.settings$continuation = true
                      } else {
                        PreferencesUtil.putSync("continuation", false)
                        this.settings$continuation = false
                      }
                    })
                }
              }
            }
          })
        }
        SettingsGroup() {
          SettingsRow({
            settingsTitle: $r("app.string.questions"),
            clickEvent: {
              action: () => {
                promptAction.showToast({
                  'message': $r("app.string.coming_soon")
                })
              }
            }
          })
          SettingsDivider()
          SettingsRow({
            settingsTitle: $r("app.string.service_info"),
            clickEvent: {
              action: () => {
                promptAction.showToast({
                  'message': $r("app.string.coming_soon")
                })
              }
            }
          })
          SettingsDivider()
          SettingsRow({
            settingsTitle: $r("app.string.about"),
            clickEvent: {
              action: () => {
                promptAction.showToast({
                  'message': $r("app.string.coming_soon")
                })
              }
            }
          })
        }
      }
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
      .then(async (photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
        if (photoSelectResult.photoUris.length == 0) {
          return
        }

        let accessor = photoAccessHelper.getPhotoAccessHelper(getContext(this))

        let duplicated = false
        for (let photoUri of photoSelectResult.photoUris) {
          let photoFile = fileIo.openSync(photoUri)
          let pre1 = await hashByFd(photoFile.fd, "sha256")
          let pre2 = await hashByFd(photoFile.fd, "sha256")
          let photoHash = await hashByFd(photoFile.fd, "sha256")
          if (this.hashes.indexOf(photoHash) >= 0) {
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
                          let videoV2 = VideoEntityV2.fromV1(video)
                          videoV2.status = FileStatus.Authorized
                          this.videos.push(videoV2)
                          this.hashes.push(video.hash)
                        })
                    })
                }
              })
          }
          if (duplicated) {
            showAlert(this.getUIContext(), $r("app.string.duplicated_imports"),
              $r("app.string.duplicated_imports_desc"))
          }
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
        let unsupported = false
        for (let fileUrl of documentSelectResult) {
          if (!fileUrl.startsWith("file://")) {
            unsupported = true
            continue
          }
          let hashValue = await hash.hash(FileUtil.getFilePath(fileUrl), "sha256")
          if (this.hashes.indexOf(hashValue) >= 0) {
            duplicated = true
          } else {
            VideoLibraryDatabase.addFromLocalFile(getContext(this), fileUrl)
              .then((video) => {
                let videoV2 = VideoEntityV2.fromV1(video)
                videoV2.status = FileStatus.Authorized
                this.videos.push(videoV2)
                this.hashes.push(video.hash)
              })
          }
        }

        if (duplicated) {
          showAlert(this.getUIContext(), $r("app.string.duplicated_imports"), $r("app.string.duplicated_imports_desc"),
            () => {
              if (unsupported) {
                showAlert(this.getUIContext(), $r("app.string.import_unsupported_source"),
                  $r("app.string.import_unsupported_source_desc"))
              }
            })
        } else if (unsupported) {
          showAlert(this.getUIContext(), $r("app.string.import_unsupported_source"),
            $r("app.string.import_unsupported_source_desc"))
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

  aboutToAppear(): void {
    checkPermissionGrant("ohos.permission.DISTRIBUTED_DATASYNC")
      .then((status: abilityAccessCtrl.GrantStatus) => {
        if (status == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          this.settings$continuation = true
        }
        if (!PreferencesUtil.getBooleanSync("continuation", false)) {
          this.settings$continuation = false
        }
      })
  }

}

import { Sys } from '../../context/SystemContext'
import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { Modifiers } from '../attributemodifier/Modifiers'
import { CircleIconButton } from '../button/CircleIconButton'
import { PlayerProgressBar } from './PlayerProgressBar'
import { LengthMetrics } from '@kit.ArkUI'
import { fileIo } from '@kit.CoreFileKit'
import { Pref } from '../../context/PreferenceContext'
import { ImportProgressContext } from '../overlay/ImportProgressOverlay'
import { ensurePath,
  fileNameAndExtension } from '../../utils/FileUtils'
import { taskpool } from '@kit.ArkTS'
import { surfaceFillingModesButton,
  surfaceFillingModesMenuItem } from './controller/items/ControllerSurfaceFillingModes'
import { audiosButton, audiosMenuItem } from './controller/items/ControllerAudios'
import { subtitlesButton, subtitlesMenuItem } from './controller/items/ControllerSubtitles'
import { speedsButton, speedsMenuItem } from './controller/items/ControllerSpeeds'
import { chapterListButton, chapterListMenuItem } from './controller/items/ControllerChapterList'
import { videoFiltersButton, videoFiltersMenuItem } from './controller/items/ControllerVideoFilters'
import { repeatButton, repeatMenuItem } from './controller/items/ControllerRepeat'
import { mirrorFlipButton, mirrorFlipMenuItem } from './controller/items/ControllerMirrorFlip'
import { Con } from '../../context/ControllerContext'
import { DraggableItem } from '../component/inner/InnerDraggable'

@ObservedV2
export class ControlsContext {
  @Trace
  showTopBarAndBottomBar: boolean = false
  @Trace
  showChapterList: boolean = false
  @Trace
  showFilterSheet: boolean = false
}

@Concurrent
function importSubtitle(uri: string, basePath: string) {
  let nameNextension = fileNameAndExtension(uri)
  let name = nameNextension[0]
  let extension = nameNextension[1]
  let added = 0
  while (fileIo.accessSync(`${basePath}/${name}${added == 0 ? "" : ` (${added})`}.${extension}`, fileIo.AccessModeType.EXIST)) {
    added += 1
  }
  if (fileIo.accessSync(`${basePath}/${name}${added == 0 ? "" : ` (${added})`}.${extension}`, fileIo.AccessModeType.EXIST)) {
    fileIo.unlinkSync(`${basePath}/${name}${added == 0 ? "" : ` (${added})`}.${extension}`)
  }
  fileIo.copyFileSync(ensurePath(uri), `${basePath}/${name}${added == 0 ? "" : ` (${added})`}.${extension}`)

  taskpool.Task.sendData(`${name}${added == 0 ? "" : ` (${added})`}.${extension}`)
}

@ComponentV2
export struct PlayerBottomBar {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Consumer("showSidebar")
  showSidebar: boolean = false
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Local
  showSurfaceFillingModeMenu: boolean = false
  @Local
  showAudiosMenu: boolean = false
  @Local
  showSubtitlesMenu: boolean = false
  @Local
  showSpeedMenu: boolean = false
  @Local
  showMoreMenu: boolean = false

  @Local
  importProgressContext: ImportProgressContext = ImportProgressContext.reach(this.getUIContext())
  @Consumer("landscape")
  landscape: boolean = true

  build() {
    Row() {
      Column() {
        PlayerProgressBar()
        Row() {
          CircleIconButton({
            icon: $r("sys.symbol.gobackward_15"),
            buttonMargin: {
              left: 16,
              bottom: 12
            },
            clickCallback: () => {
              this.playerController.goBackward(15 * 1000)
            }
          })
          this.playAndPauseButton()
          CircleIconButton({
            icon: $r("sys.symbol.goforward_15"),
            buttonMargin: {
              left: 12,
              bottom: 12
            },
            clickCallback: () => {
              this.playerController.goForward(15 * 1000)
            }
          })
          Blank()
            .layoutWeight(1)
          if ((!this.landscape && !Sys.isTablet()) || Pref.alwaysFold) {
            CircleIconButton({
              icon: $r("sys.symbol.dot_grid_2x2"),
              buttonMargin: {
                right: 16,
                bottom: 12
              },
              iconRotation: 180,
              clickCallback: () => {
                this.showMoreMenu = false // refresh menu status
                this.showMoreMenu = true
              }
            })
              .bindMenu(this.showMoreMenu!!, this.moreMenu, {
                onDisappear: () => {
                  this.showMoreMenu = false
                }
              })
          } else {
            ForEach(Con.bottomBar, (item: DraggableItem) => {
              if (item.index === 0) {
                mirrorFlipButton({
                  right: 16,
                  bottom: 12
                })
              } else if (item.index === 1) {
                repeatButton({
                  right: 16,
                  bottom: 12
                })
              } else if (item.index === 2) {
                videoFiltersButton({
                  right: 16,
                  bottom: 12
                })
              } else if (item.index === 3 && this.playerContext.chapters.length > 0) {
                chapterListButton({
                  right: 16,
                  bottom: 12
                })
              } else if (item.index === 4) {
                surfaceFillingModesButton({
                  right: 16,
                  bottom: 12
                })
              } else if (item.index === 5) {
                audiosButton({
                  right: 16,
                  bottom: 12
                })
              } else if (item.index === 6) {
                subtitlesButton({
                  right: 16,
                  bottom: 12
                })
              } else if (item.index === 7) {
                speedsButton({
                  right: 16,
                  bottom: 12
                })
              }
            })
            if (Con.bottomBarFolded.length > 0) {
              CircleIconButton({
                icon: $r("sys.symbol.dot_grid_2x2"),
                buttonMargin: {
                  right: 16,
                  bottom: 12
                },
                iconRotation: 180,
                clickCallback: () => {
                  this.showMoreMenu = false // refresh menu status
                  this.showMoreMenu = true
                }
              })
                .bindMenu(this.showMoreMenu!!, this.moreMenu, {
                  onDisappear: () => {
                    this.showMoreMenu = false
                  }
                })
            }
          }
          if (Sys.isPC()) {
            CircleIconButton({
              icon: $r("sys.symbol.open_sidebar"),
              buttonMargin: {
                right: 16,
                bottom: 12
              },
              clickCallback: () => {
                this.showSidebar = true
              }
            })
          }
        }
        .width("100%")
      }
      .borderRadius(
        Pref.uiUpdatePreview ? {
          topLeft: Pref.innerRadius,
          topRight: Pref.innerRadius,
          bottomLeft: Pref.outerRadius,
          bottomRight: Pref.outerRadius
        } : {
          topLeft: Pref.innerRadius,
          topRight: Pref.innerRadius
        }
      )
      .margin(
        Pref.uiUpdatePreview ? {
          bottom: 8,
          left: 8,
          right: 8
        } : 0
      )
      .layoutWeight(1)
      .attributeModifier(Modifiers.backgroundBlur())
    }
    .width("100%")
  }

  @Builder
  private playAndPauseButton() {
    if (!this.playerContext.video || this.playerContext.paused) {
      CircleIconButton({
        icon: $r("sys.symbol.play_fill"),
        buttonMargin: {
          left: 12,
          bottom: 12
        },
        clickCallback: () => {
          if (!this.playerContext.video) {
            return
          }
          this.playerController.play()
        }
      })
    } else {
      CircleIconButton({
        icon: $r("sys.symbol.pause"),
        buttonMargin: {
          left: 12,
          bottom: 12
        },
        clickCallback: () => {
          if (!this.playerContext.video) {
            return
          }
          this.playerController.pause()
        }
      })
    }
  }

  @Builder
  private moreMenu() {
    Menu() {
      MenuItemGroup() {
        if ((!this.landscape && !Sys.isTablet()) || Pref.alwaysFold) {
          mirrorFlipMenuItem()
          repeatMenuItem()
          videoFiltersMenuItem()
          if (this.playerContext.chapters.length > 0) {
            chapterListMenuItem()
          }
          surfaceFillingModesMenuItem()
          audiosMenuItem()
          subtitlesMenuItem()
          speedsMenuItem()
        } else {
          ForEach(Con.bottomBarFolded, (item: DraggableItem) => {
            if (item.index === 0) {
              mirrorFlipMenuItem()
            } else if (item.index === 1) {
              repeatMenuItem()
            } else if (item.index === 2) {
              videoFiltersMenuItem()
            } else if (item.index === 3 && this.playerContext.chapters.length > 0) {
              chapterListMenuItem()
            } else if (item.index === 4) {
              surfaceFillingModesMenuItem()
            } else if (item.index === 5) {
              audiosMenuItem()
            } else if (item.index === 6) {
              subtitlesMenuItem()
            } else if (item.index === 7) {
              speedsMenuItem()
            }
          })
        }
      }
    }
    .menuItemDivider({
      color: $r("sys.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
      startMargin: LengthMetrics.vp(4),
      endMargin: LengthMetrics.vp(4)
    })
  }

}
import { Pref } from '../../context/PreferenceContext'
import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { Modifiers } from '../attributemodifier/Modifiers'
import { CircleIconButton } from '../button/CircleIconButton'
import { ControlsContext } from './PlayerBottomBar'
import { LengthMetrics } from '@kit.ArkUI'
import { Sys } from '../../context/SystemContext'
import { TopCutoutAvoidArea } from '../avoidarea/TopCutoutAvoidArea'
import { chapterListButton, chapterListMenuItem } from './controller/items/ControllerChapterList'
import { mirrorFlipButton, mirrorFlipMenuItem } from './controller/items/ControllerMirrorFlip'
import { repeatButton, repeatMenuItem } from './controller/items/ControllerRepeat'
import { videoFiltersButton, videoFiltersMenuItem, VisualEffectSheet } from './controller/items/ControllerVideoFilters'
import { Con } from '../../context/ControllerContext'
import { DraggableItem } from '../component/inner/InnerDraggable'
import { surfaceFillingModesButton,
  surfaceFillingModesMenuItem } from './controller/items/ControllerSurfaceFillingModes'
import { audiosButton, audiosMenuItem } from './controller/items/ControllerAudios'
import { subtitlesButton, subtitlesMenuItem } from './controller/items/ControllerSubtitles'
import { speedsButton, speedsMenuItem } from './controller/items/ControllerSpeeds'
import { getWidthBreakpointSize } from '../../utils/ComponentUtils'
import { WindowContext } from '../../context/WindowContext'

@ComponentV2
export struct PlayerTopBar {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Local
  windowContext: WindowContext = WindowContext.reach(this.getUIContext())
  @Consumer("landscape")
  landscape: boolean = false
  @Consumer("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()

  @Local
  showMoreMenu: boolean = false

  build() {
    Row() {
      Column() {
        TopCutoutAvoidArea({
          extra: Pref.uiUpdatePreview ? -8 : 0
        })
        Row() {
          CircleIconButton({
            icon: $r("sys.symbol.chevron_left"),
            buttonMargin: {
              left: 16,
              top: 12,
              bottom: 12
            },
            clickCallback: () => {
              this.indexNavigator.pop()
            }
          })
          if (this.playerContext.videoSource?.metadata().metadata.hdr == 1) {
            Image($r("app.media.dolby_colorful"))
              .borderRadius(4)
              .height(24)
              .aspectRatio(2 / 1)
              .margin({
                left: 4
              })
          } else if (this.playerContext.videoSource?.metadata().metadata.hdr == 2) {
            Image($r("app.media.vivid_colorful_new"))
              .borderRadius(4)
              .height(24)
              .aspectRatio(2 / 1)
              .margin({
                left: 4
              })
          } else if (this.playerContext.videoSource?.metadata().metadata.hdr == 3) {
            Image($r("app.media.hdr10_plus_colorful"))
              .borderRadius(4)
              .height(24)
              .aspectRatio(2 / 1)
              .margin({
                left: 4
              })
          } else if (this.playerContext.videoSource?.metadata().metadata.hdr == 4) {
            Image($r("app.media.hdr_gold"))
              .borderRadius(4)
              .height(24)
              .aspectRatio(2 / 1)
              .margin({
                left: 4
              })
          }
          Text(this.playerContext.videoSource?.name())
            .maxLines(1)
            .textOverflow({
              overflow: TextOverflow.MARQUEE
            })
            .margin({
              left: 4,
              right: 4
            })
            .layoutWeight(3)
            .fontColor($r("sys.color.font_primary"))
          Blank()
            .layoutWeight(1)
          if (!Pref.alwaysFold && (this.landscape || Sys.isTablet()) && getWidthBreakpointSize(this.windowContext.widthBreakpoint) > 2) {
            ForEach(Con.topBar, (item: DraggableItem) => {
              if (item.index === 0) {
                mirrorFlipButton({
                  right: 16,
                  top: 12,
                  bottom: 12
                })
              } else if (item.index === 1) {
                repeatButton({
                  right: 16,
                  top: 12,
                  bottom: 12
                })
              } else if (item.index === 2) {
                videoFiltersButton({
                  right: 16,
                  top: 12,
                  bottom: 12
                })
              } else if (item.index === 3 && this.playerContext.chapters.length > 0) {
                chapterListButton({
                  right: 16,
                  top: 12,
                  bottom: 12
                })
              } else if (item.index === 4) {
                surfaceFillingModesButton({
                  right: 16,
                  top: 12,
                  bottom: 12
                })
              } else if (item.index === 5) {
                audiosButton({
                  right: 16,
                  top: 12,
                  bottom: 12
                })
              } else if (item.index === 6) {
                subtitlesButton({
                  right: 16,
                  top: 12,
                  bottom: 12
                })
              } else if (item.index === 7) {
                speedsButton({
                  right: 16,
                  top: 12,
                  bottom: 12
                })
              }
            })
            if (Con.topBarFolded.length > 0) {
              CircleIconButton({
                icon: $r("sys.symbol.dot_grid_2x2"),
                buttonMargin: {
                  right: 16,
                  top: 12,
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
        }
        .alignItems(VerticalAlign.Center)
        .width("100%")
      }
      // 因为有按钮折叠，所以不绑定在按钮上
      .bindSheet(
        this.controlsContext.showFilterSheet,
        this.VisualEffectSheet,
        {
          backgroundColor: $r("app.color.rohy_background"),
          height: SheetSize.FIT_CONTENT,
          dragBar: false,
          shadow: ShadowStyle.OUTER_DEFAULT_MD,
          showClose: true,
          preferType: SheetType.CENTER,
          enableOutsideInteractive: false,
          mode: SheetMode.OVERLAY,
          onWillDismiss: () => {
            this.controlsContext.showFilterSheet = false
          },
          title: {
            title: $r("app.string.visual_effect")
          }
        }
      )
      .borderRadius(
        Pref.uiUpdatePreview ? {
          topLeft: Pref.outerRadius,
          topRight: Pref.outerRadius,
          bottomLeft: Pref.innerRadius,
          bottomRight: Pref.innerRadius
        } : {
          bottomLeft: Pref.innerRadius,
          bottomRight: Pref.innerRadius
        }
      )
      .margin(
        Pref.uiUpdatePreview ? {
          top: 8,
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
  private moreMenu() {
    Menu() {
      MenuItemGroup() {
        ForEach(Con.topBarFolded, (item: DraggableItem) => {
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
    .menuItemDivider({
      color: $r("sys.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
      startMargin: LengthMetrics.vp(4),
      endMargin: LengthMetrics.vp(4)
    })
  }

  @Builder
  private VisualEffectSheet() {
    VisualEffectSheet({
      hideChooser: () => {
        this.controlsContext.showFilterSheet = false
      },
    })
  }

}
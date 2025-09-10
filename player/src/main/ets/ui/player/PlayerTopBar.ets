import { Pref } from '../../context/PreferenceContext'
import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { AbilityStorage } from '../../storage/AbilityStorage'
import { Modifiers } from '../attributemodifier/Modifiers'
import { TopAvoidArea } from '../avoidarea/TopAvoidArea'
import { CircleIconButton } from '../button/CircleIconButton'
import { CircleIconSwitch } from '../button/CircleIconSwitch'
import { VisualEffectSheet } from '../pages/sheet/VisualEffectSheet'
import { ControlsContext } from './PlayerBottomBar'
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI'
import { CutoutAvoidArea } from '../avoidarea/CutoutAvoidArea'
import { Sys } from '../../context/SystemContext'
import { TopCutoutAvoidArea } from '../avoidarea/TopCutoutAvoidArea'

@ComponentV2
export struct PlayerTopBar {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Consumer("landscape")
  landscape: boolean = false
  @Consumer("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()

  @Local
  private showFilterSheet: boolean = false
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
          if (this.landscape || Sys.isTablet()) {
            CircleIconSwitch({
              icon: $r("sys.symbol.trapezoid_and_line_vertical"),
              buttonMargin: {
                right: 16,
                top: 12,
                bottom: 12
              },
              switch: (value) => {
                this.playerContext.mirrorFlipping = value
                return value
              }
            })
            CircleIconSwitch({
              icon: $r("sys.symbol.repeat"),
              buttonMargin: {
                right: 16,
                top: 12,
                bottom: 12
              },
              switch: (value) => {
                this.playerContext.cycling = value
                return value
              }
            })
            CircleIconButton({
              icon: $r("sys.symbol.camera_filters"),
              buttonMargin: {
                right: 16,
                top: 12,
                bottom: 12
              },
              clickCallback: () => {
                this.showFilterSheet = true
              }
            })
            if (this.playerContext.chapters.length > 0) {
              CircleIconButton({
                icon: $r("sys.symbol.bookmark"),
                buttonMargin: {
                  right: 16,
                  top: 12,
                  bottom: 12
                },
                clickCallback: () => {
                  this.controlsContext.showChapterList = true
                }
              })
            }
          } else {
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
        .alignItems(VerticalAlign.Center)
        .width("100%")
      }
      // 因为有按钮折叠，所以不绑定在按钮上
      .bindSheet(
        this.showFilterSheet,
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
            this.showFilterSheet = false
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
        MenuItem({
          symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.trapezoid_and_line_vertical")),
          content: $r("app.string.mirror_flip"),
          symbolEndIcon: this.playerContext.mirrorFlipping ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined,
        })
          .onClick(() => {
            this.playerContext.mirrorFlipping = !this.playerContext.mirrorFlipping
          })
        MenuItem({
          symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.repeat")),
          content: $r("app.string.loop_playing"),
          symbolEndIcon: this.playerContext.cycling ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            this.playerContext.cycling = !this.playerContext.cycling
          })
        MenuItem({
          symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.camera_filters")),
          content: $r("app.string.visual_effect")
        })
          .onClick(() => {
            this.showFilterSheet = true
          })
        if (this.playerContext.chapters.length > 0) {
          MenuItem({
            symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.bookmark")),
            content: $r("app.string.chapter_list")
          })
            .onClick(() => {
              this.controlsContext.showChapterList = true
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

  @Builder
  private VisualEffectSheet() {
    VisualEffectSheet({
      hideChooser: () => {
        this.showFilterSheet = false
      },
    })
  }

}
import { Sys } from '../../../context/SystemContext'
import { PlayerContext } from '../../../player/PlayerContext'
import { PlayerController } from '../../../player/PlayerController'
import { AbilityStorage } from '../../../storage/AbilityStorage'
import { Modifiers } from '../../attributemodifier/Modifiers'
import { CircleIconButton } from '../../button/CircleIconButton'
import { PlayerProgressBar } from './PlayerProgressBar'
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI'
import { TrackMetadata } from '../../../metadata/TrackMetadata'
import { pickSingleSubtitleFile } from '../../../utils/PickerUtils'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { compile } from '../../../lib/ass_compiler'
import { SubtitleInfo } from '../../../subtitle/SubtitleInfo'

@ComponentV2
export struct PlayerBottomBar {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Consumer("showSidebar")
  showSidebar: boolean = false
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  @Local
  showSubtitlesMenu: boolean = false
  @Local
  showSpeedMenu: boolean = false

  build() {
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
        CircleIconButton({
          icon: $r("sys.symbol.questionmark_circle"),
          buttonMargin: {
            right: 16,
            bottom: 12
          },
          clickCallback: () => {
            this.showSubtitlesMenu = false // refresh menu status
            this.showSubtitlesMenu = true
          }
        })
          .bindMenu(this.showSubtitlesMenu!!, this.subtitlesMenu, {
            onDisappear: () => {
              this.showSubtitlesMenu = false
            }
          })
        CircleIconButton({
          icon: $r("sys.symbol.chevron_left_2"),
          buttonMargin: {
            right: 16,
            bottom: 12
          },
          iconRotation: 180,
          clickCallback: () => {
            this.showSpeedMenu = false // refresh menu status
            this.showSpeedMenu = true
          }
        })
          .bindMenu(this.showSpeedMenu!!, this.speedMenu, {
            onDisappear: () => {
              this.showSpeedMenu = false
            }
          })
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
    .borderRadius({
      topLeft: 16,
      topRight: 16
    })
    .width("100%")
    .attributeModifier(Modifiers.backgroundBlur())
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
  private speedMenu() {
    Menu() {
      ForEach([0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0], (speed: number) => {
        if (this.playerContext.playSpeed == speed) {
          MenuItem({
            content: this.speedToText(speed),
            symbolEndIcon: new SymbolGlyphModifier($r("sys.symbol.checkmark")).fontSize(24)
          })
        } else {
          MenuItem({
            content: this.speedToText(speed),
          })
            .onClick(() => {
              this.playerController.setSpeed(speed)
            })
        }
      })
    }
  }

  @Builder
  private subtitlesMenu() {
    Menu() {
      MenuItemGroup() {
        MenuItem({
          content: $r('app.string.no_subtitle'),
          symbolEndIcon: this.playerContext.selectedSubtitle == undefined ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
        })
          .onClick(() => {
            if (this.playerContext.selectedSubtitle == undefined)
              return
            this.playerContext.selectedSubtitle = undefined
          })
      }
      if (this.playerContext.subtitles.length > 0) {
        MenuItemGroup() {
          ForEach(this.playerContext.subtitles, (subtitle: SubtitleInfo, index) => {
            MenuItem({
              content: subtitle.title,
              symbolEndIcon: this.playerContext.selectedSubtitle === index ? new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
            })
              .onClick(() => {
                if (this.playerContext.selectedSubtitle == index)
                  return
                this.playerContext.selectedSubtitle = index
              })
          })
        }
      }
      MenuItemGroup() {
        MenuItem({
          content: $r('app.string.open_subtitle')
        })
          .onClick(() => {
            pickSingleSubtitleFile(this.getUIContext())
              .then((file) => {
                if (file == undefined)
                  return
                if (!file.endsWith(".ass"))
                  return
                let compiledASS = compile(fileIo.readTextSync(new fileUri.FileUri(file).path), void 0)
                let title = compiledASS.info.Title
                if (title == undefined || title == "")
                  title = new fileUri.FileUri(file).name
                this.playerContext.subtitles.push({
                  title: title,
                  language: undefined,
                  url: file,
                  type: 'ass'
                })
              })
          })
      }
    }
    .menuItemGroupDivider({
      color: $r("sys.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(8),
      startMargin: LengthMetrics.vp(0),
      endMargin: LengthMetrics.vp(0)
    })
  }

  private speedToText(speed: number): ResourceStr {
    switch (speed) {
      case 0.25:
        return $r("app.string.speed_0_25")
      case 0.5:
        return $r("app.string.speed_0_50")
      case 0.75:
        return $r("app.string.speed_0_75")
      case 1.25:
        return $r("app.string.speed_1_25")
      case 1.5:
        return $r("app.string.speed_1_50")
      case 1.75:
        return $r("app.string.speed_1_75")
      case 2:
        return $r("app.string.speed_2_00")
      default:
        return $r("app.string.speed_1_00")
    }
  }
}
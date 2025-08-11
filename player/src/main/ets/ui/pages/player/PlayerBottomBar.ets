import { Sys } from '../../../context/SystemContext'
import { PlayerContext } from '../../../player/PlayerContext'
import { PlayerController } from '../../../player/PlayerController'
import { AbilityStorage } from '../../../storage/AbilityStorage'
import { Modifiers } from '../../attributemodifier/Modifiers'
import { CircleIconButton } from '../../button/CircleIconButton'
import { PlayerProgressBar } from './PlayerProgressBar'
import { SymbolGlyphModifier } from '@kit.ArkUI'

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
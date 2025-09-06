import { Pref } from '../../context/PreferenceContext'
import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { AbilityStorage } from '../../storage/AbilityStorage'
import { Modifiers } from '../attributemodifier/Modifiers'
import { TopAvoidArea } from '../avoidarea/TopAvoidArea'
import { CircleIconButton } from '../button/CircleIconButton'
import { ControlsContext } from './PlayerBottomBar'

@ComponentV2
export struct PlayerTopBar {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!
  @Consumer("landscape")
  landscape: boolean = false
  @Consumer("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()

  build() {
    Row() {
      Column() {
        if (!this.landscape) {
          TopAvoidArea()
        }
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
        }
        .alignItems(VerticalAlign.Center)
        .width("100%")
      }
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
}
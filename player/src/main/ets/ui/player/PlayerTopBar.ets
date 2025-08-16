import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { AbilityStorage } from '../../storage/AbilityStorage'
import { Modifiers } from '../attributemodifier/Modifiers'
import { TopAvoidArea } from '../avoidarea/TopAvoidArea'
import { CircleIconButton } from '../button/CircleIconButton'
import { WindowManager } from '../manager/WindowManager'

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

  build() {
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
            WindowManager.setFullscreen(this.getUIContext(), false)
            WindowManager.setStatusBar(this.getUIContext(), true)
            WindowManager.setNavigationIndicator(this.getUIContext(), true)
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
      }
      .alignItems(VerticalAlign.Center)
      .width("100%")
    }
    .borderRadius({
      bottomLeft: 16,
      bottomRight: 16
    })
    .width("100%")
    .attributeModifier(Modifiers.backgroundBlur())
  }
}
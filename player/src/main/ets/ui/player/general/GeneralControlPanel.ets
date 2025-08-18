import { PlayerContext } from '../../../player/PlayerContext'
import { PlayerController } from '../../../player/PlayerController'
import { AbilityStorage } from '../../../storage/AbilityStorage'
import { BottomBarContext, PlayerBottomBar } from '../PlayerBottomBar'
import { curves } from '@kit.ArkUI'
import { PlayerTopBar } from '../PlayerTopBar'
import { HandGestureModifier } from '../../gesture/HandGestureModifier'

@ComponentV2
export struct GeneralControlPanel {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Local
  bottomBarContext: BottomBarContext = new BottomBarContext()

  build() {
    Column() {
      PlayerTopBar()
        .focusable(false)
        .visibility(this.bottomBarContext.shown ? Visibility.Visible : Visibility.Hidden)
        .animation({
          curve: curves.springMotion(),
          duration: 200
        })
        .transition(TransitionEffect.move(TransitionEdge.TOP).combine(TransitionEffect.OPACITY))
      Blank()
        .gestureModifier(new HandGestureModifier(this.playerController, this.bottomBarContext))
        .layoutWeight(1)
      PlayerBottomBar()
        .focusable(false)
        .visibility(this.bottomBarContext.shown ? Visibility.Visible : Visibility.Hidden)
        .animation({
          curve: curves.springMotion(),
          duration: 200
        })
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY))
    }
    .width("100%")
    .height("100%")
  }
}
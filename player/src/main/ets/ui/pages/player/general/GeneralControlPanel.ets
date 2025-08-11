import { PlayerContext } from '../../../../player/PlayerContext'
import { PlayerController } from '../../../../player/PlayerController'
import { AbilityStorage } from '../../../../storage/AbilityStorage'
import { PlayerBottomBar } from '../PlayerBottomBar'
import { curves } from '@kit.ArkUI'
import { PlayerTopBar } from '../PlayerTopBar'

@ComponentV2
export struct GeneralControlPanel {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!
  @Local
  showControllerBar: boolean = false

  build() {
    Column() {
      PlayerTopBar()
        .focusable(false)
        .visibility(this.showControllerBar ? Visibility.Visible : Visibility.Hidden)
        .animation({
          curve: curves.springMotion(),
          duration: 200
        })
        .transition(TransitionEffect.move(TransitionEdge.TOP).combine(TransitionEffect.OPACITY))
      Blank()
        .onClick(() => {
          this.showControllerBar = !this.showControllerBar
        })
        .layoutWeight(1)
      PlayerBottomBar()
        .focusable(false)
        .visibility(this.showControllerBar ? Visibility.Visible : Visibility.Hidden)
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
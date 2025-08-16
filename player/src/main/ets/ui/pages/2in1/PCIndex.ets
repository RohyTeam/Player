import { DropPage } from './DropPage'
import { PCControlPanel } from '../../player/pc/PCControlPanel'
import { curves } from '@kit.ArkUI'
import { PlaylistSideBar } from './PlaylistSideBar'
import { AbilityStorage } from '../../../storage/AbilityStorage'
import { PlayerController } from '../../../player/PlayerController'
import { PlayerContext } from '../../../player/PlayerContext'
import { PlayerPage } from '../../player/PlayerPage'
import { PCKeyboardHandler } from '../../handler/PCKeyboardHandler'

@ObservedV2
class NumberContainer {
  @Trace
  value: number

  constructor(value?: number) {
    this.value = value ?? 0
  }
}

@ComponentV2
export struct PCIndex {
  @Local
  showPlayList: boolean = false
  @Provider("showSidebar")
  showSidebar: boolean = false
  @Provider("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  build() {
    Column() {
      SideBarContainer(SideBarContainerType.Overlay) {
        // sidebar
        PlaylistSideBar()
          .borderRadius(16)
          .margin({
            top: 16,
            right: 16,
            bottom: 16
          })
          .visibility(this.showSidebar ? Visibility.Visible : Visibility.Hidden)
          .animation({
            curve: curves.springMotion(),
            duration: 200
          })
          .transition(
            TransitionEffect.asymmetric(
              TransitionEffect.OPACITY
                .combine(TransitionEffect.move(TransitionEdge.END))
                .combine(TransitionEffect.scale({ x: 0, y: 0, centerX: 0 })),
              TransitionEffect.OPACITY
                .combine(TransitionEffect.move(TransitionEdge.END))
            )
          )

        // content
        Stack() {
          if (this.playerContext.video && this.playerContext.videoSource != undefined) {
            PlayerPage({
              videoSource: this.playerContext.videoSource
            })
              .zIndex(1)
          } else {
            DropPage()
              .zIndex(1)
          }
          PCControlPanel()
            .zIndex(2)
          if (this.showSidebar) {
            // an overlay
            Column()
              .onClick(() => {
                this.showSidebar = false
              })
              .width("100%")
              .height("100%")
              .zIndex(3)
          }
        }
        .width("100%")
        .height("100%")
      }
      .focusable(true)
      .defaultFocus(true)
      .onKeyPreIme((event) => {
        console.error(`fuck keyboard: trying solving keyboard`)
        return PCKeyboardHandler.handle(this.getUIContext(), this.playerController, event)
      })
      .width("100%")
      .height("100%")
      .divider({
        strokeWidth: 0
      })
      .autoHide(true)
      .showControlButton(false)
      .showSideBar(true)
      .sideBarWidth("33%")
      .sideBarPosition(SideBarPosition.End)
      .backgroundColor(Color.Transparent)
    }
    .backgroundColor(Color.Transparent)
    .width("100%")
    .height("100%")
  }
}
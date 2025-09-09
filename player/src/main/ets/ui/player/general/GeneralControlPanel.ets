import { PlayerContext } from '../../../player/PlayerContext'
import { PlayerController } from '../../../player/PlayerController'
import { ControlsContext, PlayerBottomBar } from '../PlayerBottomBar'
import { curves } from '@kit.ArkUI'
import { PlayerTopBar } from '../PlayerTopBar'
import { HandGestureModifier } from '../../gesture/HandGestureModifier'
import { AVVolumePanel } from '@ohos.multimedia.avVolumePanel'
import { Sys } from '../../../context/SystemContext'
import { clamp } from '../../../utils/MathUtils'
import { convertNumberToDurationString } from '../../../utils/NumberUtils'
import { ChapterSidebar } from '../ChapterSidebar'

@ComponentV2
export struct GeneralControlPanel {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Provider("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()
  @Consumer("landscape")
  landscape: boolean = true

  build() {
    SideBarContainer(SideBarContainerType.Overlay) {
      ChapterSidebar()
        .borderRadius(16)
        .margin({
          top: 16,
          right: 16,
          bottom: 16
        })
        .visibility(this.controlsContext.showChapterList ? Visibility.Visible : Visibility.None)
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

      Column() {
        PlayerTopBar()
          .focusable(false)
          .visibility(this.controlsContext.showTopBarAndBottomBar ? Visibility.Visible : Visibility.None)
          .transition(
            TransitionEffect.move(TransitionEdge.TOP)
              .combine(TransitionEffect.OPACITY)
              .animation({
                curve: curves.springMotion(),
                duration: 200
              })
          )
        Stack() {
          Column() {
            if (this.playerContext.speedingUp) {
              SmallTips({
                content: $r("app.string.speeding_up")
              })
            }
            if (this.playerContext.adjustingVolume) {
              SmallTips({
                content: $r("app.string.adjusting_volume",
                  `${clamp(Math.round((this.playerContext.currentVolume / Sys.maxVolume) * 100), 0, 100)}%`)
              })
            }
            if (this.playerContext.adjustingScreenBrightness) {
              SmallTips({
                content: $r("app.string.adjusting_brightness",
                  `${clamp(Math.round((this.playerContext.currentScreenBrightness / 255) * 100), 0, 100)}%`)
              })
            }
            if (Sys.time - this.playerContext.lastTimeForward <= 1000) {
              SmallTips({
                content: $r("app.string.forwarded")
              })
            }
            if (Sys.time - this.playerContext.lastTimeBackward <= 1000) {
              SmallTips({
                content: $r("app.string.backwarded")
              })
            }
            Blank()
              .layoutWeight(1)
            if (this.playerContext.movingPosition) {
              SmallTips({
                content: $r(
                  "app.string.adjusting_progress",
                  convertNumberToDurationString(this.playerContext.targetPosition),
                  convertNumberToDurationString(this.playerContext.maxDuration)
                )
              })
            }
          }
          .height("100%")
          .width("100%")

          Column() {
            Blank()
              .gestureModifier(new HandGestureModifier(this.playerController, this.playerContext, this.controlsContext))
              .layoutWeight(1)
          }
          .height("100%")
          .width("100%")
        }
        .width("100%")
        .layoutWeight(1)

        AVVolumePanel({
          volumeLevel: this.playerContext.currentVolume,
          volumeParameter: {
            position: {
              x: -1,
              y: -1
            }
          }
        })
          .visibility(Visibility.None)
        PlayerBottomBar()
          .focusable(false)
          .visibility(this.controlsContext.showTopBarAndBottomBar ? Visibility.Visible : Visibility.None)
          .transition(
            TransitionEffect.move(TransitionEdge.BOTTOM)
              .combine(TransitionEffect.OPACITY)
              .animation({
                curve: curves.springMotion(),
                duration: 200
              })
          )
      }
      .width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
    .divider({
      strokeWidth: 0
    })
    .autoHide(true)
    .showControlButton(false)
    .showSideBar(true)
    .sideBarWidth(this.landscape ? "40%" : "80%")
    .sideBarPosition(SideBarPosition.End)
    .backgroundColor(Color.Transparent)
  }
}

@ComponentV2
struct SmallTips {
  @Param
  @Require
  content: ResourceStr

  build() {
    Column() {
      Text(this.content)
        .fontColor(Color.White)
        .fontSize(24)
    }
    .backgroundColor("#a1000000")
    .borderRadius(8)
    .padding(16)
    .margin({
      top: 4,
      bottom: 4
    })
  }
}
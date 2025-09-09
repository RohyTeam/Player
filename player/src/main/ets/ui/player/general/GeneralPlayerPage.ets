import { PlayerContext } from '../../../player/PlayerContext'
import { PlayerController } from '../../../player/PlayerController'
import { WindowManager } from '../../manager/WindowManager'
import { PlayerPage } from '../PlayerPage'
import { GeneralControlPanel } from './GeneralControlPanel'
import { window } from '@kit.ArkUI'
import { AVSessionContext } from '../../../context/AVSessionContext'
import { Sys } from '../../../context/SystemContext'
import { BackgroundTaskContext } from '../../../context/BackgroundTaskContext'

@ComponentV2
export struct GeneralPlayerPage {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Provider("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Provider("landscape")
  landscape: boolean = false

  aboutToAppear(): void {
    // WindowManager.setFullscreen(this.getUIContext(), true)
    WindowManager.setStatusBar(this.getUIContext(), false)
    WindowManager.setNavigationIndicator(this.getUIContext(), false)

    let metadata = this.playerContext.videoSource!.metadata()!.metadata
    if (metadata.width >= metadata.height && !Sys.isTablet()) {
      WindowManager.setOrientation(this.getUIContext(), window.Orientation.AUTO_ROTATION_LANDSCAPE)
      this.landscape = true
    }

    AVSessionContext.startSession(this.getUIContext(), this.playerContext.videoSource!, this.playerController)
  }

  aboutToDisappear(): void {
    // WindowManager.setFullscreen(this.getUIContext(), false)
    WindowManager.setStatusBar(this.getUIContext(), true)
    WindowManager.setNavigationIndicator(this.getUIContext(), true)

    if (this.landscape && !Sys.isTablet()) {
      WindowManager.setOrientation(this.getUIContext(), window.Orientation.PORTRAIT)
    }

    AVSessionContext.stopSession()
  }

  build() {
    NavDestination() {
      Stack() {
        if (!this.playerContext.video || this.playerContext.videoSource == undefined) {
          // 如果有其他原因导致视频停止播放（比如播控中心）及时将当前页面关闭
          Column()
            .onAppear(() => {
              this.indexNavigator.pop()
            })
        }
        PlayerPage({
          videoSource: this.playerContext.videoSource
        })
          .zIndex(1)
        GeneralControlPanel()
          .zIndex(2)
      }
      .width("100%")
      .height("100%")
    }
    .backgroundColor(Color.Black)
    .hideTitleBar(true)
    .hideToolBar(true)
    .hideBackButton(true)
  }
}
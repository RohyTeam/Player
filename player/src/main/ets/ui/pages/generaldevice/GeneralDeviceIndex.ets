import { Wanter } from '../../../context/WantAnnouncer'
import { PlaylistDao } from '../../../database/dao/PlaylistDao'
import { PlayerContext } from '../../../player/PlayerContext'
import { GeneralPlayerPage } from '../../player/general/GeneralPlayerPage'
import { PlaylistFolderView } from '../../player/general/playlist/PlaylistFolderView'
import { DebugPage } from '../debug/DebugPage'
import { RohyPlayerDebugPage } from '../debug/RohyPlayerDebugPage'
import { GeneralPlaylistView } from '../../player/general/playlist/GeneralPlaylistListView'
import { IndexMenuButtons } from './IndexMenuButtons'
import { AboutPage } from '../misc/AboutPage'
import { QnAPage } from '../misc/QnAPage'
import { VisualStylePage } from './VisualStylePage'
import { DataSources } from '../../../datasource/DataSources'
import { Sys } from '../../../context/SystemContext'
import { getWidthBreakpointSize } from '../../../utils/ComponentUtils'
import { WindowContext } from '../../../context/WindowContext'
import { curves } from '@kit.ArkUI'
import { CircleIconButton } from '../../button/CircleIconButton'

@ComponentV2
export struct GeneralDeviceIndex {
  @Provider("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Local
  windowContext: WindowContext = WindowContext.reach(this.getUIContext())
  @Local
  searching: boolean = false
  @Provider('hideSearch')
  hideSearch: boolean = false

  onDidBuild(): void {
    if (this.playerContext.video && this.playerContext.videoSource != undefined) {
      this.indexNavigator.pushPath({ name: "Player" })
    }
  }

  build() {
    Navigation(this.indexNavigator) {
      if (Wanter.announced) {
        Column() {
        }
        .onAppear(() => {
          if (this.playerContext.video && this.playerContext.videoSource != undefined) {
            this.indexNavigator.pushPath({ name: "Player" })
          }
          Wanter.announced = false
        })
      }
      // TODO: search bar
      if (getWidthBreakpointSize(this.windowContext.widthBreakpoint) <= 2 && !this.hideSearch) {
        Row() {
          if (this.searching) {
            CircleIconButton({
              icon: $r('sys.symbol.chevron_left'),
              buttonMargin: {
                right: 8
              },
              clickCallback: () => {
                this.getUIContext().getFocusController().clearFocus()
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  this.searching = false
                })
              }
            })
              .transition(
                TransitionEffect.OPACITY
                  .combine(TransitionEffect.move(TransitionEdge.START))
              )
              .id('focus_escaper')
          }
          Search({
            placeholder: $r("app.string.search")
          })
            .layoutWeight(1)
            .height(40)
            .onSubmit((value) => {
            })
            .onFocus(() => {
              animateTo({
                duration: 200,
                curve: curves.springMotion()
              }, () => {
                this.searching = true
              })
            })
            .onBlur(() => {
              animateTo({
                duration: 200,
                curve: curves.springMotion()
              }, () => {
                this.searching = false
              })
            })
        }
        .transition(
          TransitionEffect.OPACITY
            .combine(
              TransitionEffect.scale({
                y: 0,
                centerY: 0
              })
            )
        )
        .width("90%")
        .height(40)
      }
      if (!this.searching) {
        GeneralPlaylistView()
          .onAppear(() => {
            // 放在这里让 ui 加载出来再重载，这样不会卡在 startIcon 页
            DataSources.PLAYLIST.reloadInitially()
          })
      }
    }
    .menus(this.searching ? undefined : this.menuButtons)
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.rohy_background"))
    .navDestination(this.IndexPager)
    .hideBackButton(true)
    .hideToolBar(true)
    .hideTitleBar(this.searching)
    .title(
      $r("app.string.playlist"),
      {
        backgroundColor: $r("app.color.rohy_background"),
        // backgroundBlurStyle: BlurStyle.Regular,
      }
    )
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }

  @Builder
  private menuButtons() {
    IndexMenuButtons()
  }

  @Builder
  IndexPager(name: string, params?: Record<string, object>) {
    if (name == "Player") {
      GeneralPlayerPage()
    } else if (name.startsWith('PlaylistView')) {
      PlaylistFolderView({
        data: params!["dao"] as PlaylistDao,
        path: params!["path"] as number[]
      })
    } else if (name == "DebugPage") {
      DebugPage()
    } else if (name == 'RohyPlayerDebugPage') {
      RohyPlayerDebugPage()
    }
  }

}
import { Pref } from '../../../context/PreferenceContext'
import { Wanter } from '../../../context/WantAnnouncer'
import { PlayerContext } from '../../../player/PlayerContext'
import { AbilityStorage } from '../../../storage/AbilityStorage'
import { GeneralPlayerPage } from '../../player/general/GeneralPlayerPage'
import { IndexMenuButtons } from './IndexMenuButtons'

@ComponentV2
export struct GeneralDeviceIndex {
  @Provider("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  onDidBuild(): void {
    if (this.playerContext.video && this.playerContext.videoSource != undefined) {
      this.indexNavigator.pushPath({ name: "Player" })
    }
  }

  build() {
    Navigation(this.indexNavigator) {
      List() {
        if (Wanter.announced) {
          ListItem() {

          }
          .onAppear(() => {
            if (this.playerContext.video && this.playerContext.videoSource != undefined) {
              this.indexNavigator.pushPath({ name: "Player" })
            }
            Wanter.announced = false
          })
        }
      }
      .width("100%")
      .height("100%")
    }
    .menus(this.menuButtons)
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.rohy_background"))
    .navDestination(this.IndexPager)
    .hideBackButton(true)
    .hideToolBar(true)
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
  IndexPager(name: string) {
    if (name == "Player") {
      GeneralPlayerPage()
    }
  }
}
import { InnerButton } from '../../component/inner/InnerButton'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'

@ComponentV2
export struct DebugPage {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      InnerContainer({
        bgColor: Color.Transparent
      }) {
        InnerComponentSet() {
          InnerButton({
            title: "rohy player test",
            showGoToIcon: true,
            clickCallback: () => {
              this.indexNavigator.pushPath({ name: 'RohyPlayerDebugPage' })
            }
          })
        }
      }
    }
    .backgroundColor($r("app.color.rohy_background"))
    .hideTitleBar(false)
    .hideToolBar(true)
    .hideBackButton(false)
    .title("debug page")
    .width("100%")
    .height("100%")
  }
}
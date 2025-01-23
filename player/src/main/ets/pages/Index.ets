import { RohyPlayerHome } from './rohyplayer/HomeScreen';

@Entry
@Component
struct Index {
  build() {
    RelativeContainer() {
      Navigation() {
        RohyPlayerHome()
      }
      .backgroundColor($r("app.color.comp_background_focus"))
      .height('100%')
      .width('100%')
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .hideBackButton(true)
      .hideToolBar(true)
    }
    .backgroundColor($r("app.color.comp_background_focus"))
    .height('100%')
    .width('100%')
  }
}
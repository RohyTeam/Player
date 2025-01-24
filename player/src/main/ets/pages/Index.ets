import { RohyPlayerHome } from './rohyplayer/HomeScreen';

@Entry
@Component
struct Index {

  @StorageLink('appColorMode')
  colorMode: string = "system";

  build() {
    WithTheme({
      colorMode: this.colorMode == "system" ? ThemeColorMode.SYSTEM: this.colorMode == "dark" ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
    }) {
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

}
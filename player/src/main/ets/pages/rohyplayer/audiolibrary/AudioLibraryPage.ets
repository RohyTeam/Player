@Component
export struct AudioLibraryPage {

  build() {
    Navigation() {
      Text($r("app.string.coming_soon"))
    }
    .hideBackButton(true)
    .titleMode(NavigationTitleMode.Mini)
    .title($r("app.string.home_tab_audio"))
    .height("100%")
    .width("100%")
  }

}
@Component
export struct PlaylistPage {
  build() {
    Navigation() {
      Text($r("app.string.coming_soon"))
    }
    .hideBackButton(true)
    .titleMode(NavigationTitleMode.Mini)
    .title($r("app.string.home_tab_playlist"))
    .height("100%")
    .width("100%")
  }
}
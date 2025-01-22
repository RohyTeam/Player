@Component
export struct MorePage {

  build() {
    Navigation() {
      Text($r("app.string.coming_soon"))
    }
    .hideBackButton(true)
    .titleMode(NavigationTitleMode.Mini)
    .title($r("app.string.home_tab_more"))
    .height("100%")
    .width("100%")
  }

}
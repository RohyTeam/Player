@ComponentV2
export struct GeneralDeviceIndex {

  build() {
    Navigation() {
    }
    .width("100%")
    .height("100%")
    .backgroundColor(Color.Transparent)
    .navDestination(this.IndexPager)
    .hideBackButton(true)
    .hideToolBar(true)
    .title(
      $r("app.string.playlist"),
      {
        backgroundColor: $r("app.color.rohy_background"),
        backgroundBlurStyle: BlurStyle.Regular,
      }
    )
    .mode(NavigationMode.Stack)
  }

  @Builder
  IndexPager(name: string) {

  }

}
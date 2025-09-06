@ComponentV2
export struct SimpleLoadingPage {
  build() {
    Column() {
      Blank()
        .layoutWeight(5)
      LoadingProgress()
        .enableLoading(true)
        .color($r("sys.color.icon_secondary"))
        .width(64)
        .height(64)
      Blank()
        .layoutWeight(6)
    }
    .backgroundColor(Color.Transparent)
    .height("100%")
    .width("100%")
  }
}
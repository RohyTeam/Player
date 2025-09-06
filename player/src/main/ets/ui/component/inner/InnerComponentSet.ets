
@ComponentV2
export struct InnerComponentSet {
  @BuilderParam
  content: () => void

  build() {
    Column() {
      this.content()
    }
    .width("90%")
    .backgroundColor($r("app.color.rohy_card"))
    .borderRadius(16)
    .padding(4)
  }
}
@ComponentV2
export struct InnerDivider {
  build() {
    Divider()
      .width("100%")
      .margin({
        left: 8,
        right: 8
      })
  }
}
@ComponentV2
export struct InnerContainerText {
  @Param
  @Require
  text: ResourceStr
  @Param
  textColor?: ResourceColor = undefined

  build() {
    Column() {
      Text(this.text)
        .fontColor(this.textColor)
        .padding({
          bottom: 2
        })
    }
    .width("89%")
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Color.Transparent)
  }
}
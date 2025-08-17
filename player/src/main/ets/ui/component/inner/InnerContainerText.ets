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
    }
    .width("90%")
    .backgroundColor(Color.Transparent)
  }

}
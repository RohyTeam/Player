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

@ComponentV2
export struct InnerContainerTextCustomizable {

  @Param
  textColor?: ResourceColor = undefined

  @BuilderParam
  builder: () => void

  build() {
    Column() {
      Text() {
        this.builder()
      }
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
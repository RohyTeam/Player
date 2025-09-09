import { Modifiers } from "../../attributemodifier/Modifiers"

@ComponentV2
export struct InnerComponentSet {
  @Param
  blurredBackground: boolean = false
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
    .attributeModifier(Modifiers.optionalBackgroundBlur(this.blurredBackground))
  }
}
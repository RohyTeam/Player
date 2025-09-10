import { Modifiers } from "../attributemodifier/Modifiers"

@ComponentV2
export struct CircleIconButton {
  @Param
  @Require
  icon: Resource
  @Param
  isSymbol: boolean = true
  @Param
  iconRotation: number = 0
  @Param
  buttonMargin: Margin = {}
  @Param
  blurredBackground: boolean = false
  @Param
  bgColor: Resource = $r("sys.color.comp_background_tertiary")
  @Event
  clickCallback: () => void = () => {
  }

  build() {
    Button({
      type: ButtonType.Circle
    }) {
      if (this.isSymbol) {
        SymbolGlyph(this.icon)
          .fontSize(24)
          .fontColor([$r("sys.color.icon_primary")])
          .rotate({
            angle: this.iconRotation,
            z: 1,
            centerX: "50%",
            centerY: "50%",
          })
          .symbolEffect(new BounceSymbolEffect(EffectScope.LAYER, EffectDirection.DOWN))
      } else {
        Image(this.icon)
          .width(24)
          .height(24)
          .rotate({
            angle: this.iconRotation,
            z: 1,
            centerX: "50%",
            centerY: "50%",
          })
      }
    }
    .clickEffect({
      level: ClickEffectLevel.LIGHT,
      scale: 0.8
    })
    .attributeModifier(Modifiers.optionalBackgroundBlur(this.blurredBackground))
    .align(Alignment.Center)
    .margin(this.buttonMargin)
    .width(40)
    .height(40)
    .onClick(this.clickCallback)
    .backgroundColor(this.bgColor)
  }
}
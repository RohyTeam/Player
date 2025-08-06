@ComponentV2
export struct CircleIconButton {

  @Param
  @Require
  icon: Resource

  @Param
  buttonMargin: Margin = {}

  @Event
  clickCallback: () => void = () => {}

  build() {
    Button({
      type: ButtonType.Circle
    }) {
      SymbolGlyph(this.icon)
        .fontSize(24)
        .fontColor([$r("sys.color.icon_primary")])
    }
    .clickEffect({
      level: ClickEffectLevel.LIGHT,
      scale: 0.8
    })
    .align(Alignment.Center)
    .margin(this.buttonMargin)
    .width(40)
    .height(40)
    .onClick(this.clickCallback)
    .backgroundColor($r("sys.color.comp_background_tertiary"))
  }

}
import { curves } from "@kit.ArkUI"

@ComponentV2
export struct CircleIconSwitch {
  @Param
  @Require
  icon: Resource
  @Param
  initial: boolean = false
  @Param
  isSymbol: boolean = true
  @Param
  symbolNormalColor: ResourceColor = $r("sys.color.icon_primary")
  @Param
  symbolActiveColor: ResourceColor = Color.White
  @Param
  iconRotation: number = 0
  @Param
  buttonMargin: Margin = {}
  @Param
  backgroundNormalColor: Resource = $r("sys.color.comp_background_tertiary")
  @Param
  backgroundActiveColor: Resource = $r("sys.color.brand")
  @Event
  switch: (value: boolean) => boolean = (it) => {
    return it
  }

  @Local
  private value: boolean = false

  aboutToAppear() {
    this.value = this.initial
  }

  build() {
    Button({
      type: ButtonType.Circle
    }) {
      if (this.isSymbol) {
        SymbolGlyph(this.icon)
          .fontSize(24)
          .fontColor(this.value ? [this.symbolActiveColor] : [this.symbolNormalColor])
          .rotate({
            angle: this.iconRotation,
            z: 1,
            centerX: "50%",
            centerY: "50%",
          })
          .symbolEffect(new BounceSymbolEffect(EffectScope.LAYER, EffectDirection.DOWN))
          .animation({
            duration: 200,
            curve: curves.springMotion()
          })
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
    .align(Alignment.Center)
    .margin(this.buttonMargin)
    .width(40)
    .height(40)
    .onClick(() => {
      this.value = this.switch(!this.value)
    })
    .transition(
      TransitionEffect.scale({ x: 0.8, y: 0.8 })
        .animation({
          duration: 200,
          curve: curves.springMotion()
        })
    )
    .animation({
      duration: 200,
      curve: curves.springMotion()
    })
    .backgroundColor(this.value ? this.backgroundActiveColor : this.backgroundNormalColor)
  }
}
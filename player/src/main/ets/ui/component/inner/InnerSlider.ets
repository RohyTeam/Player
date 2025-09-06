import { clamp } from '../../../utils/MathUtils'

@ComponentV2
export struct InnerSlider {
  @Param
  @Require
  title: ResourceStr
  @Param
  quickUpdate: boolean = false
  @Param
  @Require
  min: number
  @Param
  @Require
  max: number
  @Param
  initialValue: number = 0
  @Param
  step: number = 1
  @Param
  showSteps: boolean = false
  @Param
  larger: boolean = false
  @Param
  italic: boolean = false
  @Param
  subtitle: ResourceStr | undefined = undefined
  @Param
  popup: ResourceStr | undefined = undefined
  @Event
  onChange: (value: number) => boolean = () => {
    return true
  }
  @Local
  private showPopup: boolean = false
  @Local
  private value: number = 0
  @Local
  private lastStart: number = 0

  @Builder
  popupText() {
    Column() {
      Text(this.popup)
        .fontColor($r("sys.color.font_primary"))
        .padding(16)
    }
    .constraintSize({
      maxWidth: "50%"
    })
  }

  aboutToAppear(): void {
    this.value = clamp(this.initialValue, this.min, this.max)
    this.lastStart = this.value
  }

  build() {
    Row() {
      Row() {
        Column() {
          Text(this.title)
            .fontStyle(this.italic ? FontStyle.Italic : FontStyle.Normal)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r("sys.color.font_primary"))
          if (this.subtitle != undefined) {
            Text(this.subtitle)
              .fontSize(14)
              .fontColor($r("sys.color.font_secondary"))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .margin({
          left: 8,
          top: 8,
          bottom: 8
        })

        if (this.popup != undefined) {
          SymbolGlyph($r('sys.symbol.questionmark_circle'))
            .fontSize(20)
            .fontColor([$r('sys.color.icon_primary')])
            .onClick(() => {
              this.showPopup = true
            })
            .margin({
              left: 4
            })
            .bindPopup(
              this.showPopup,
              {
                builder: this.popupText,
                placement: Placement.Bottom,
                enableArrow: true,
                showInSubWindow: false,
                popupColor: $r("app.color.rohy_card"),
                backgroundBlurStyle: BlurStyle.NONE,
                onStateChange: (state) => {
                  if (!state.isVisible) {
                    this.showPopup = false
                  }
                }
              }
            )
        }
        Blank()
          .layoutWeight(1)
        Slider({
          min: this.min,
          max: this.max,
          value: this.value,
          step: this.step
        })
          .showSteps(this.showSteps)
          .onChange((value, mode) => {
            if (mode == SliderChangeMode.Begin) {
              this.lastStart = value
            }
            if (this.quickUpdate) {
              this.onChange(value)
            } else {
              if (mode == SliderChangeMode.End || mode == SliderChangeMode.Click) {
                if (this.onChange(value)) {
                  this.value = value
                } else {
                  this.value = this.lastStart
                }
              }
            }
          })
          .layoutWeight(4)
      }
      .alignItems(VerticalAlign.Center)
      .borderRadius(12)
      .width("100%")
      .height("100%")
      .backgroundColor($r("app.color.rohy_card"))
    }
    .height(this.larger ? "56vp" : "48vp")
    .width("100%")
  }
}
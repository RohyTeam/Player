import { clamp } from '../../../utils/MathUtils'
import { CounterComponent, CounterType } from '@ohos.arkui.advanced.Counter'

@ComponentV2
export struct InnerCounter {
  @Param
  @Require
  title: ResourceStr
  @Param
  @Require
  min: number
  @Param
  @Require
  max: number
  @Param
  step: number = 1
  @Param
  larger: boolean = false
  @Param
  subtitle: ResourceStr | undefined = undefined
  @Param
  popup: ResourceStr | undefined = undefined
  @Param
  initialValue: number = 0
  @Event
  onChange: (value: number) => void = () => {
  }
  @Local
  private showPopup: boolean = false
  @Local
  private value: number = 0

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
  }

  build() {
    Row() {
      Row() {
        Column() {
          Text(this.title)
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
        CounterComponent({
          options: {
            type: CounterType.COMPACT,
            numberOptions: {
              value: this.value,
              min: this.min,
              max: this.max,
              step: this.step,
              onChange: (value) => {
                this.onChange(value)
              }
            }
          }
        })
          .margin({
            right: 8
          })
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
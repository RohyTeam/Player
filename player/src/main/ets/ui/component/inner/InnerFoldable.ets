import { curves } from '@kit.ArkUI'

@ComponentV2
export struct InnerFoldable {
  @Param
  @Require
  title: ResourceStr
  @Param
  larger: boolean = false
  @Param
  subtitle: ResourceStr | undefined = undefined
  @Param
  popup: ResourceStr | undefined = undefined
  @Local
  private showPopup: boolean = false
  @Local
  private folded: boolean = true
  @BuilderParam
  content: () => void

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

  build() {
    Row() {
      Column() {
        Button() {
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

            Text() {
              SymbolSpan($r("sys.symbol.arrowtriangle_down_fill"))
            }
            .textAlign(TextAlign.Center)
            .fontColor($r("sys.color.icon_primary"))
            .margin({
              left: 8,
              right: 8,
              top: 12,
              bottom: 12,
            })
            .width(20)
            .height(20)
            .fontSize(20)
            .rotate({
              z: 1,
              centerX: "50%",
              centerY: "50%",
              angle: this.folded ? 180 : 0
            })
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          animateTo({
            duration: 200,
            curve: curves.springMotion()
          }, () => {
            this.folded = !this.folded
          })
        })
        .borderRadius(12)
        .width("100%")
        .height("100%")
        .type(ButtonType.Normal)
        .height(this.larger ? "56vp" : "48vp")
        .backgroundColor($r("app.color.rohy_card"))

        if (!this.folded) {
          Column() {
            this.content()
          }
          .padding(8)
          .transition(
            TransitionEffect.translate({ y: 0 })
              .combine(TransitionEffect.scale({ y: 0, centerY: 0 }))
              .combine(TransitionEffect.OPACITY)
          )
          .width("100%")
        }
      }
      .width("100%")
    }
    .width("100%")
  }
}
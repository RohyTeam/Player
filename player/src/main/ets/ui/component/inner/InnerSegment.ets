import { ItemRestriction, SegmentButtonOptions, SegmentButtonTextItem } from '@kit.ArkUI'
import { MySegmentButtonV2 } from '../v2/MySegmentButtonV2'

export interface SegmentChoice {

  title: ResourceStr
  action: () => void

}

@ComponentV2
export struct InnerSegment {
  @Param
  @Require
  title: ResourceStr
  @Param
  larger: boolean = false
  @Param
  subtitle: ResourceStr | undefined = undefined
  @Param
  popup: ResourceStr | undefined = undefined
  @Param
  blankSize: number = 2
  @Param
  initialSelected: number = 0
  @Param
  @Require
  choices: SegmentChoice[]
  @Local
  private showPopup: boolean = false
  segmentOptions: SegmentButtonOptions | undefined = undefined

  aboutToAppear(): void {
    let buttonItems: SegmentButtonTextItem[] = []
    for (let choice of this.choices) {
      if (buttonItems.length >= 5) {
        break
      }
      let buttonItem: SegmentButtonTextItem = {
        text: choice.title
      }
      buttonItems.push(buttonItem)
    }
    this.segmentOptions = SegmentButtonOptions.capsule({
      buttons: buttonItems as ItemRestriction<SegmentButtonTextItem>
    })
  }

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
          .layoutWeight(this.blankSize)
        MySegmentButtonV2({
          options: this.segmentOptions,
          selected: this.initialSelected < 0 || this.initialSelected >= this.choices.length ? 0 : this.initialSelected,
          callback: {
            callback: (selected) => {
              if (selected < 0 || selected >= this.choices.length) {
                return
              }
              this.choices[selected].action()
            }
          }
        })
          .layoutWeight(3)
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
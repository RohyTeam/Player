import { ItemRestriction, SegmentButtonOptions, SegmentButtonTextItem, SymbolGlyphModifier } from '@kit.ArkUI'
import { MySegmentButtonV2 } from '../v2/MySegmentButtonV2'

export interface SelectChoice {

  icon?: Resource
  symbol?: boolean
  title: ResourceStr
  action: () => void

}

@ComponentV2
export struct InnerSelect {
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
  choices: SelectChoice[]
  @Local
  private selected: number = 0
  @Local
  private showPopup: boolean = false
  @Local
  private selectOptions: SelectOption[] = []

  aboutToAppear(): void {
    for (let choice of this.choices) {
      if (choice.icon !== undefined) {
        if (choice.symbol !== undefined && !choice.symbol) {
          this.selectOptions.push({
            icon: choice.icon,
            value: choice.title
          })
        } else {
          this.selectOptions.push({
            symbolIcon: new SymbolGlyphModifier(choice.icon),
            value: choice.title
          })
        }
      } else {
        this.selectOptions.push({
          value: choice.title
        })
      }
    }
    this.selected = Math.max(0, Math.min(this.initialSelected, this.choices.length))
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
        Select(this.selectOptions)
          .selected(this.selected)
          .value(this.choices[this.selected].title)
          .height(this.larger ? 28 : 24)
          .onSelect((index) => {
            this.selected = index
            this.choices[index].action()
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
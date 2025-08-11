@ComponentV2
export struct InnerButtonWithImage {
  @Param
  @Require
  image: PixelMap | ResourceStr | DrawableDescriptor | ImageContent
  @Param
  @Require
  title: ResourceStr
  @Param
  subtitle: ResourceStr | undefined = undefined
  @Param
  popup: ResourceStr | undefined = undefined
  @Param
  showGoToIcon: boolean = false
  @Param
  imageOutline: boolean = true
  @Event
  clickCallback: () => void = () => {
  }
  @Local
  private showPopup: boolean = false

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
      Button() {
        Row() {
          Image(this.image)
            .width("48vp")
            .height("48vp")
            .margin(8)
            .border(
              this.imageOutline ? {
                width: 1,
                radius: 12,
                color: $r("sys.color.icon_fourth")
              } : undefined
            )
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
          if (this.showGoToIcon) {
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(20)
              .fontColor([$r('sys.color.icon_primary')])
              .margin({
                right: 8
              })
          }
        }
        .alignItems(VerticalAlign.Center)
      }
      .onClick(this.clickCallback)
      .borderRadius(12)
      .width("100%")
      .height("100%")
      .type(ButtonType.Normal)
      .backgroundColor($r("app.color.rohy_card"))
    }
    .height("64vp")
    .width("100%")
  }
}
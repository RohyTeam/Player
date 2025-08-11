@ComponentV2
export struct InnerSwitch {
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
  initialValue: boolean = false
  @Event
  switch: (original: boolean) => boolean = () => {
    return false
  }
  @Local
  private showPopup: boolean = false
  @Local
  private isOn: boolean = this.initialValue

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
          .layoutWeight(1)
        Toggle({
          type: ToggleType.Switch,
          isOn: this.isOn
        })
          .margin({
            right: 8
          })
          .onChange(() => {
            this.isOn = this.switch(this.isOn)
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

@Builder
export function openVideoWaitingDialog() {
  Column() {
    LoadingProgress()
      .enableLoading(true)
      .color($r("sys.color.icon_secondary"))
      .width(64)
      .height(64)
  }
  .alignItems(HorizontalAlign.Start)
  .backgroundColor($r("app.color.rohy_card"))
  .borderRadius(16)
  .padding(12)
  .margin(16)
}
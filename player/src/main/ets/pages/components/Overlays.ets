@CustomDialog
@Component
export struct LoadingOverlay {
  controller?: CustomDialogController

  build() {
    Column() {
      LoadingProgress()
        .enableLoading(true)
        .color($r("app.color.icon_secondary"))
        .width(64)
        .height(64)
        .margin(32)
    }
    .borderRadius(16)
  }
}

@CustomDialog
@Component
export struct ProgressLoadingOverlay {
  @Link
  loading: number
  @Link
  loaded: number
  controller?: CustomDialogController

  build() {
    Column() {
      Text($r('app.string.importing', this.loaded, this.loading))
        .fontSize(18)
        .margin({
          left: 12,
          right: 12,
          top: 24,
          bottom: 4
        })
      Progress({
        value: this.loaded,
        total: this.loading,
        type: ProgressType.Linear
      }).margin({
        left: 12,
        right: 12,
        bottom: 24
      })
    }
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
  }
}
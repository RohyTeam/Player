@ComponentV2
export struct ImportProgressOverlay {
  @Param
  @Require
  context: ImportProgressContext

  build() {
    Column() {
      Text($r('app.string.importing', `${this.context.current}`, `${this.context.total}`))
        .fontSize(18)
        .margin({
          left: 12,
          right: 12,
          top: 24,
          bottom: 4
        })
      Progress({
        value: this.context.current,
        total: this.context.total,
        type: ProgressType.Linear
      }).margin({
        left: 12,
        right: 12,
        bottom: 24
      })
      Text(this.context.subProgressText)
        .fontSize(18)
        .margin({
          left: 12,
          right: 12,
          top: 24,
          bottom: 4
        })
      Progress({
        value: this.context.subProgressCurrent,
        total: this.context.subProgressTotal,
        type: ProgressType.Linear
      }).margin({
        left: 12,
        right: 12,
        bottom: 24
      })
    }
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r("app.color.rohy_card"))
    .borderRadius(16)
    .padding(12)
    .margin(16)
  }
}

@ObservedV2
export class ImportProgressContext {
  @Trace
  current: number = 0
  @Trace
  total: number = 0
  @Trace
  subProgressText: ResourceStr = ""
  @Trace
  subProgressCurrent: number = 0
  @Trace
  subProgressTotal: number = 0
}

@Builder
export function ImportProgressOverlayBuilder(context: ImportProgressContext) {
  ImportProgressOverlay({
    context: context
  })
}
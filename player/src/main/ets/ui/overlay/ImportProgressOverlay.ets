import { DialogHelper } from "@pura/harmony-dialog"
import { AbilityStorage } from "../../storage/AbilityStorage"

@ComponentV2
export struct ImportProgressOverlay {
  @Local
  context: ImportProgressContext = ImportProgressContext.reach(this.getUIContext())

  build() {
    Column() {
      Text($r('app.string.importing', `${this.context.current}`, `${this.context.total}`))
        .fontSize(18)
        .margin(4)
      Progress({
        value: this.context.current,
        total: this.context.total,
        type: ProgressType.Linear
      })
        .margin(4)
      if (this.context.total > 0) {
        Text(this.context.subProgressText)
          .fontSize(18)
          .margin(4)
        Progress({
          value: this.context.subProgressCurrent,
          total: this.context.subProgressTotal,
          type: ProgressType.Linear
        })
          .margin(4)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Color.Transparent)
    .borderRadius(16)
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

  public static reach(context: UIContext | Context): ImportProgressContext {
    return AbilityStorage.connect(
      context,
      ImportProgressContext,
      "import_progress_context",
      () => new ImportProgressContext()
    )!
  }

}

@Builder
function importProgressContent() {
  ImportProgressOverlay()
}

export function showEasyImportProgressDialog(cancelCallback: () => void): string {
  return DialogHelper.showCustomContentDialog({
    primaryTitle: $r("app.string.import_video"),
    contentBuilder: importProgressContent,
    buttons: [
      {
        value: $r("app.string.cancel"),
        fontColor: $r("sys.color.font_primary")
      }
    ],
    onAction: (action: number, dialogId: string): void => {
      DialogHelper.closeDialog(dialogId)
      cancelCallback()
    }
  })
}
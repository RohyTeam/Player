import { DialogHelper } from "@pura/harmony-dialog";
import { fileName } from "../../../../../utils/FileUtils";
import { ImportError, ImportErrorType } from "../PlaylistMenuButtons";

@ObservedV2
class Errors {

  @Trace
  errors: ImportError[] = []

}

let globalErrors: Errors = new Errors()

@Builder
function importErrorContent() {
  ForEach(listifiedErrors(optimizeErrors(globalErrors.errors)), (urls: string[], index: number) => {
    if (urls.length > 0) {
      Text() {
        Span(ImportErrorType.TYPES[index].reason)
          .fontColor($r('sys.color.warning'))
        ForEach(urls, (uri: string) => {
          Span('\n' + `  ·  ${fileName(uri)}`)
        })
      }
      .margin(8)
    }
  })
}

export function showEasyImportErrorDialog(errors: ImportError[]) {
  globalErrors.errors = errors
  DialogHelper.showCustomContentDialog({
    primaryTitle: $r("app.string.import_error"),
    contentBuilder: importErrorContent,
    buttons: [
      {
        value: $r("app.string.confirm"),
        fontColor: $r("sys.color.font_primary")
      }
    ],
    onAction: (action: number, dialogId: string): void => {
      DialogHelper.closeDialog(dialogId)
    }
  })
}

@Builder
export function importErrorDialog(errors: ImportError[]) {
  Column() {
    ForEach(listifiedErrors(optimizeErrors(errors)), (urls: string[], index: number) => {
      if (urls.length > 0) {
        Text() {
          Span(ImportErrorType.TYPES[index].reason)
            .fontColor($r('sys.color.warning'))
          ForEach(urls, (uri: string) => {
            Span('\n' + `  ${fileName(uri)}`)
          })
        }
        .margin(8)
      }
    })
    /*
    Text($r("app.string.unknown_error_desc"))
      .fontColor($r('sys.color.warning'))
      .margin(8)*/
  }
  .alignItems(HorizontalAlign.Start)
  .backgroundColor($r("app.color.rohy_card"))
  .borderRadius(16)
  .padding(12)
  .margin(16)
}

function listifiedErrors(errors: Record<number, string[]>): string[][] {
  let listifiedErrors: string[][] = []

  for (let i = 0; i < ImportErrorType.length; i++) {
    listifiedErrors.push(errors[i] ?? [])
  }

  return listifiedErrors
}

function optimizeErrors(errors: ImportError[]): Record<number, string[]> {
  let optimizedErrors: Record<number, string[]> = {}
  for (let error of errors) {
    let index = ImportErrorType.TYPES.indexOf(error.reason)
    if (index < 0)
      continue
    if (!optimizedErrors[index])
      optimizedErrors[index] = []
    optimizedErrors[index].push(error.url)
  }
  return optimizedErrors
}
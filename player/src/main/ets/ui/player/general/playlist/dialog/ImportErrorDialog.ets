import { DialogHelper } from "@pura/harmony-dialog";
import { fileName } from "../../../../../utils/FileUtils";
import { ImportError, ImportErrorType } from "../PlaylistMenuButtons";
import { List } from "@kit.ArkTS";

@ObservedV2
class Errors {

  @Trace
  errors: ErrorProblems[] = []

}

let globalErrors: Errors = new Errors()

interface ErrorProblems {

  errorType: ImportErrorType
  urls: string[]

}

@Builder
function importErrorContent() {
  ForEach(globalErrors.errors, (problems: ErrorProblems) => {
    Text() {
      Span(problems.errorType.reason)
        .fontColor($r('sys.color.warning'))
        .fontSize(16)
      ForEach(problems.urls, (uri: string) => {
        Span('\n' + `  ·  ${fileName(uri)}`)
      })
    }
    .margin(8)
  })
}

export function showEasyImportErrorDialog(errors: ImportError[]) {
  globalErrors.errors = errorsToProblems(errors)
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

function errorsToProblems(errors: ImportError[]): ErrorProblems[] {
  let problems: Map<ImportErrorType, ErrorProblems> = new Map()
  for (let error of errors) {
    if (!problems.has(error.reason))
      problems.set(error.reason, {
        errorType: error.reason,
        urls: []
      })
    problems.get(error.reason)!.urls.push(error.url)
  }
  let problemArray: ErrorProblems[] = []
  for (let problem of problems.values()){
    problemArray.push(problem)
  }
  return problemArray
}
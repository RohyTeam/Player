import { CircleIconButton } from "../../../button/CircleIconButton"
import { PlaylistImportSheet } from "./sheet/PlaylistImportSheet"

@ComponentV2
export struct PlaylistMenuButtons {

  @Local
  private showImportVideoSheet: boolean = false

  build() {
    Row() {
      CircleIconButton({
        icon: $r("sys.symbol.plus"),
        buttonMargin: {
          right: 8
        },
        clickCallback: () => {
          this.showImportVideoSheet = true
        }
      })
        .bindSheet(
          this.showImportVideoSheet!!,
          this.ImportVideoSheet,
          {
            backgroundColor: $r("app.color.rohy_background"),
            height: SheetSize.FIT_CONTENT,
            dragBar: false,
            shadow: ShadowStyle.OUTER_DEFAULT_MD,
            showClose: true,
            preferType: SheetType.CENTER,
            enableOutsideInteractive: false,
            mode: SheetMode.OVERLAY,
            onWillDismiss: () => {
              this.showImportVideoSheet = false
            },
            title: {
              title: $r("app.string.import_video"),
              subtitle: $r("app.string.not_implemented")
            }
          }
        )
    }
    .margin({
      right: 8,
      top: 8
    })
  }

  @Builder
  private ImportVideoSheet() {
    PlaylistImportSheet({
      hideChooser: () => {
        this.showImportVideoSheet = false
      }
    })
  }

}
import { LengthMetrics } from '@kit.ArkUI'
import { hash, picker } from '@kit.CoreFileKit'
import { FileUtil } from '@pura/harmony-utils'
import { BusinessError } from '@kit.BasicServicesKit'
import { showAlert } from '../../../util/AlertUtil'
import { FontEntityV2, Fonts } from '../../../entity/FontEntity'
import { FontLibraryDatabase } from '../../../database/FontLibraryDatabase'
import { DialogHelper } from '@pura/harmony-dialog'
import { FileStatus } from '../../../entity/VideoEntity'

@Component
export struct FontManagementGroup {
  @Link
  fonts: Fonts
  @State
  private showingFonts: boolean = false

  aboutToAppear() {
    this.showingFonts = this.fonts.length <= 8
  }

  build() {
    Column() {
      Row() {
        Stack() {
          SymbolGlyph($r("sys.symbol.arrowtriangle_down_fill"))
            .fontColor([$r("app.color.icon_primary")])
            .margin({
              left: 8,
              top: 8,
              bottom: 8
            })
            .width(24)
            .height(24)
            .fontSize(24)
        }
        .width(40)
        .height(40)
        .margin({
          left: 4,
          top: 4,
          bottom: 4
        })
        .rotate({
          z: 1,
          angle: !this.showingFonts ? -90 : 0
        })

        Text($r("app.string.page_more_subheader_fonts"))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.font_primary"))
          .margin({
            top: 16,
            bottom: 16
          })
        Blank()
          .layoutWeight(1)
        Button({
          type: ButtonType.Normal,
        }) {
          Text($r("app.string.add_font"))
            .fontColor($r("app.color.brand"))
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showFontPicker()
        })
        .margin(16)
      }
      .onClick(() => {
        animateTo({
          duration: 200,
          curve: Curve.Linear,
          playMode: PlayMode.Normal
        }, () => {
          this.showingFonts = !this.showingFonts
        })
      })
      .width("100%")

      if (this.showingFonts) {
        ForEach(this.fonts, (font: FontEntityV2) => {
          FontRow({
            fonts: this.fonts,
            font: font
          })
        })
      }
    }
    .borderRadius(12)
    .backgroundColor($r("app.color.rohy_card"))
    .width("90%")
  }

  private showFontPicker() {
    let documentViewPicker = new picker.DocumentViewPicker(this.getUIContext().getHostContext()!);
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 10; // 太多了处理不过来
    documentSelectOptions.fileSuffixFilters = ['freetype 字体|.ttf'];

    documentViewPicker.select(documentSelectOptions)
      .then(async (documentSelectResult: Array<string>) => {
        if (documentSelectResult.length == 0) {
          return
        }

        let hashes = this.fonts.map((font) => font.hash)

        let duplicated = false
        for (let fileUrl of documentSelectResult) {
          let hashValue = await hash.hash(FileUtil.getFilePath(fileUrl), "sha256")
          if (hashes.indexOf(hashValue) >= 0) {
            duplicated = true
            continue
          }
          FontLibraryDatabase.add(getContext(this), fileUrl)
            .then((font) => {
              this.fonts.push(FontEntityV2.fromV1(font))
            })
        }

        if (duplicated) {
          showAlert(this.getUIContext(), $r("app.string.duplicated_imports"),
            $r("app.string.duplicated_imports_desc"))
        }
      }).catch((err: BusinessError) => {
      console.error(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
    })
  }
}

@Component
struct FontRow {
  @Link
  fonts: Fonts
  @Prop
  font: FontEntityV2

  build() {
    Row() {
      Text(this.font.familyName)
        .margin(16)
        .fontSize(16)
      Blank()
        .layoutWeight(1)
      Toggle({
        type: ToggleType.Switch,
        isOn: this.font.on
      })
        .margin({
          right: 16
        })
        .onChange((value) => {
          animateTo({
            duration: 200,
            curve: Curve.Linear,
            playMode: PlayMode.Normal
          }, () => {
            FontLibraryDatabase.changeUseByHash(getContext(this), this.font.hash, value)
              .then(() => {
                this.font.on = value
              })
          })
        })
    }
    .bindContextMenu(this.contextMenu, ResponseType.LongPress)
    .width("100%")
  }

  @Builder
  contextMenu() {
    Menu() {
      MenuItemGroup() {
        MenuItem()
        MenuItem() {
          Row() {
            Text($r("app.string.delete"))
              .fontColor($r("app.color.warning"))
              .fontWeight(FontWeight.Medium)
              .margin({
                left: 12,
                top: 14,
                bottom: 14
              })
          }
          .alignItems(VerticalAlign.Center)
        }
        .onClick(() => {
          DialogHelper.showAlertDialog({
            primaryTitle: $r("app.string.confirm_to_delete"),
            content: $r("app.string.confirm_to_delete_desc"),
            primaryButton: {
              value: $r("app.string.delete"),
              fontColor: $r("app.color.warning"),
              action: () => {
                let index = this.fonts.indexOf(this.font)
                if (index >= 0) {
                  this.fonts.splice(index, 1)
                }
                this.font.status = FileStatus.Disappear
                FontLibraryDatabase.deleteByFontHash(getContext(this), this.font.hash)
              }
            },
            secondaryButton: {
              value: $r("app.string.cancel"),
              fontColor: $r("app.color.brand")
            },
            onAction: (action: number, dialogId: string): void => {
              DialogHelper.closeDialog(dialogId)
            }
          })
        })
        .margin({
          top: 4,
          bottom: 4,
          left: 4,
          right: 4
        })
      }
    }
    .menuItemGroupDivider({
      color: $r("app.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
    })
    .padding(0)
  }
}
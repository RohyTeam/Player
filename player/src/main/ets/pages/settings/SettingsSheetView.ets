import { AboutPage } from './information/AboutPage'
import { PrivacyPage } from './information/Privacy'
import { LogExportPage } from './log/LogExportPage'
import { ToolbarButtonsLandscapeCustomizer } from './ToolbarCustomizer'

export interface SettingsSheetViewFunctions {

  onClose: () => void

}

@Component
export struct SettingsSheetView {
  @Prop
  @Require
  title: ResourceStr
  @Prop
  @Require
  functions: SettingsSheetViewFunctions
  @Prop
  @Require
  mainView: WrappedBuilder<[NavPathStack, SettingsSheetViewFunctions]>
  @Provide('settingsPageController')
  settingsPageController: NavPathStack = new NavPathStack()

  @Builder
  private settingsPage(name: string) {
    if (name == 'toolbarCustomization') {
      ToolbarButtonsLandscapeCustomizer()
    } else if (name == 'about') {
      AboutPage()
    } else if (name == 'logExport') {
      LogExportPage()
    } else if (name == 'privacy') {
      PrivacyPage()
    }
  }

  build() {
    Stack() {
      Navigation(this.settingsPageController) {
        Column() {
          Row() {
            Text(this.title)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r("app.color.font_primary"))
              .margin(16)
            Blank()
              .layoutWeight(1)
          }
          .margin({
            left: 12,
            right: 12,
            top: 12
          })
          .backgroundColor($r("app.color.rohy_settings_background"))

          Blank()
            .height(12)
            .width("100%")
          this.mainView.builder(this.settingsPageController, this.functions)
        }
        .backgroundColor($r("app.color.rohy_settings_background"))
        .height("100%")
        .width("100%")
      }
      .navDestination(this.settingsPage)
      .backgroundColor($r("app.color.comp_background_focus"))
      .height('100%')
      .width('100%')
      .mode(NavigationMode.Stack)
      .hideTitleBar(true)
      .hideBackButton(true)
      .hideToolBar(true)

      // 这个是为了保持始终存在一个关闭按钮
      // 放在下面保证关闭按钮始终位于 z 轴最顶层
      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.xmark"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .onClick(() => {
        this.functions.onClose()
      })
      .align(Alignment.Center)
      .margin({
        right: 24,
        top: 24
      })
      .width(40)
      .height(40)
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .alignContent(Alignment.TopEnd)
    .backgroundColor($r("app.color.rohy_settings_background"))
    .height("100%")
    .width("100%")
  }
}
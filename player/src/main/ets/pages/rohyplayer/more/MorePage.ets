import { FontManagementGroup } from './FontManagementGroup';
import { Fonts } from '../../../entity/FontEntity';
import { WebDAVs } from '../../../entity/WebDAVEntity';
import { WebDAVManagementGroup } from './WebDAVManagementGroup';
import { SettingsSheetView, SettingsSheetViewFunctions } from '../../settings/SettingsSheetView';
import { MoreSettingsPage } from '../../settings/pages/MoreSettingsPage';

@Component
export struct MorePage {
  @Link
  fonts: Fonts
  @Link
  webdavs: WebDAVs
  @State
  showSettings: boolean = false
  @StorageLink('appColorMode')
  colorMode: string = "system";
  colorModes: string[] = ["system", "light", "dark"];
  @Consume('pageController')
  pageController: NavPathStack

  build() {
    Column() {
      this.titleBar($r("app.string.home_tab_more"))
      List({ space: 12 }) {
        ListItem() {
          WebDAVManagementGroup({
            webdavs: this.webdavs
          })
        }
        .width("100%")

        ListItem() {
          FontManagementGroup({
            fonts: this.fonts
          })
        }
        .width("100%")
      }
      .height("100%")
      .width("100%")
    }
    .backgroundColor($r("app.color.comp_background_focus"))
    .height("100%")
    .width("100%")
  }

  @Builder
  settings() {
    SettingsSheetView({
      title: $r("app.string.settings"),
      functions: {
        onClose: () => {
          this.showSettings = false
        }
      },
      mainView: wrapBuilder(settingsContent)
    })
  }

  @Builder
  menus() {
    Row() {
      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.gearshape"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .align(Alignment.Center)
      .margin({
        right: 12
      })
      .width(40)
      .height(40)
      .onClick(() => {
        this.showSettings = true
      })
      .bindSheet(
        $$this.showSettings,
        this.settings(),
        {
          height: SheetSize.LARGE,
          showClose: false,
          shadow: ShadowStyle.OUTER_DEFAULT_MD,
          enableOutsideInteractive: false,
          shouldDismiss: (sheetDismiss) => {
            sheetDismiss.dismiss()
            this.showSettings = false
          },
          onWillDismiss: () => {
            this.showSettings = false
          },
          backgroundColor: $r("app.color.rohy_settings_background")
        }
      )
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .alignItems(VerticalAlign.Center)
    .height("100%")
  }

  @Builder
  private titleBar(title: ResourceStr) {
    Column() {
      Row() {
        Text(title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.font_primary"))
          .margin(16)
        Blank()
          .layoutWeight(1)
        this.menus()
      }
      .height("56vp")
      .width("100%")
    }
    .height("56vp")
    .width("100%")
  }
}

@Builder
function settingsContent(settingsPageController: NavPathStack, functions: SettingsSheetViewFunctions) {
  MoreSettingsPage({
    functions: functions
  })
}
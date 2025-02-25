import {
  SettingsDivider,
  SettingsGroup,
  SettingsPage,
  SettingsRow,
  SettingsSelection
} from '../../components/SettingsPage';
import { promptAction } from '@kit.ArkUI';
import { PreferencesUtil } from '@pura/harmony-utils';
import { FontManagementGroup } from './FontManagementGroup';
import { Fonts } from '../../../entity/FontEntity';
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { WebDAVs } from '../../../entity/WebDAVEntity';
import { WebDAVManagementGroup } from './WebDAVManagementGroup';

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
  settingsTitle() {
    Row() {
      Text($r("app.string.settings"))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r("app.color.font_primary"))
        .margin(16)
      Blank()
        .layoutWeight(1)

      Button({
        type: ButtonType.Circle
      }) {
        SymbolGlyph($r("sys.symbol.xmark"))
          .fontSize(24)
          .fontColor([$r("app.color.icon_primary")])
      }
      .onClick(() => {
        this.showSettings = false
      })
      .align(Alignment.Center)
      .margin({
        right: 12
      })
      .width(40)
      .height(40)
      .backgroundColor($r("app.color.comp_background_tertiary"))
    }
    .margin({
      left: 12,
      right: 12,
      top: 12
    })
    .backgroundColor($r("app.color.rohy_settings_background"))
  }

  @Builder
  settings() {
    Column() {
      this.settingsTitle()
      Blank()
        .height(12)
        .width("100%")
      SettingsPage() {
        SettingsGroup() {
          SettingsSelection({
            settingsTitle: $r("app.string.color_mode"),
            choices: [
              {
                title: $r("app.string.color_mode_system"),
                onSwitch: () => {
                  (getContext(this) as common.UIAbilityContext).config.colorMode =
                    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
                  AppStorage.setOrCreate("appColorMode", "system")
                  PreferencesUtil.putSync("colorMode", "system")
                }
              },
              {
                title: $r("app.string.color_mode_light"),
                onSwitch: () => {
                  (getContext(this) as common.UIAbilityContext).config.colorMode =
                    ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
                  AppStorage.setOrCreate("appColorMode", "light")
                  PreferencesUtil.putSync("colorMode", "light")
                }
              },
              {
                title: $r("app.string.color_mode_dark"),
                onSwitch: () => {
                  (getContext(this) as common.UIAbilityContext).config.colorMode =
                    ConfigurationConstant.ColorMode.COLOR_MODE_DARK
                  AppStorage.setOrCreate("appColorMode", "dark")
                  PreferencesUtil.putSync("colorMode", "dark")
                }
              }
            ],
            selectedButtons: [this.colorModes.indexOf(this.colorMode)]
          })
        }

        SettingsGroup() {
          SettingsRow({
            settingsTitle: $r("app.string.questions"),
            clickEvent: {
              action: () => {
                promptAction.showToast({
                  'message': $r("app.string.coming_soon")
                })
              }
            }
          })
          SettingsDivider()
          SettingsRow({
            settingsTitle: $r("app.string.service_info"),
            clickEvent: {
              action: () => {
                promptAction.showToast({
                  'message': $r("app.string.coming_soon")
                })
              }
            }
          })
          SettingsDivider()
          SettingsRow({
            settingsTitle: $r("app.string.about"),
            clickEvent: {
              action: () => {
                promptAction.showToast({
                  'message': $r("app.string.coming_soon")
                })
              }
            }
          })
        }

        SettingsGroup() {
          SettingsRow({
            settingsTitle: $r("app.string.settings_debug_page"),
            clickEvent: {
              action: () => {
                this.pageController.pushPath({ name: "debugPage" })
                this.showSettings = false
              }
            }
          })
        }
      }
    }
    .backgroundColor($r("app.color.rohy_settings_background"))
    .height("100%")
    .width("100%")
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
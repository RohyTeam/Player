import { PreferencesUtil } from '@pura/harmony-utils'
import {
  SettingsDivider,
  SettingsGroup,
  SettingsPage,
  SettingsRow,
  SettingsSelection,
  SettingsSwitch
} from '../../components/SettingsPage'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { SettingsSheetViewFunctions } from '../SettingsSheetView'

@Component
export struct MoreSettingsPage {
  @Prop
  @Require
  functions: SettingsSheetViewFunctions
  @Consume('pageController')
  pageController: NavPathStack
  @Consume('settingsPageController')
  settingsPageController: NavPathStack
  @StorageLink('appColorMode')
  colorMode: string = "system";
  colorModes: string[] = ["system", "light", "dark"];
  @StorageLink('save5logsOnly')
  save5logsOnly: boolean = false;

  @StorageLink("debugMode")
  private debugMode: boolean = false

  build() {
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
          selectedButton: this.colorModes.indexOf(this.colorMode)
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
          settingsTitle: $r("app.string.privacy_policy"),
          clickEvent: {
            action: () => {
              this.settingsPageController.pushPath({
                name: 'privacy'
              })
            }
          }
        })
        SettingsDivider()
        SettingsRow({
          settingsTitle: $r("app.string.about"),
          clickEvent: {
            action: () => {
              this.settingsPageController.pushPath({
                name: 'about'
              })
            }
          }
        })
      }

      if (this.debugMode) {
        SettingsGroup() {
          SettingsSwitch({
            settingsTitle: $r('app.string.debug_mode'),
            switchValue: this.debugMode,
            switchEvent: {
              action: (value: boolean) => {
                AppStorage.setOrCreate("debugMode", value)
              }
            }
          })
          SettingsDivider()
          SettingsRow({
            settingsTitle: $r("app.string.settings_debug_page"),
            clickEvent: {
              action: () => {
                this.pageController.pushPath({ name: "debugPage" })
                this.functions.onClose()
              }
            }
          })
          SettingsDivider()
          SettingsSwitch({
            settingsTitle: $r('app.string.settings_save_5_logs_only'),
            settingsTips: $r("app.string.settings_save_5_logs_only_tips"),
            switchValue: this.save5logsOnly,
            switchEvent: {
              action: (value: boolean) => {
                AppStorage.setOrCreate("save5logsOnly", value)
                PreferencesUtil.putSync("save5logsOnly", value)
              }
            }
          })
          SettingsDivider()
          SettingsRow({
            settingsTitle: $r("app.string.log_export"),
            clickEvent: {
              action: () => {
                this.settingsPageController.pushPath({ name: "logExport" })
              }
            }
          })
        }
      }
    }
  }
}
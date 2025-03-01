import { PreferencesUtil } from '@pura/harmony-utils'
import {
  SettingsDivider,
  SettingsGroup,
  SettingsPage,
  SettingsRow,
  SettingsSelection,
  SettingsSwitch
} from '../components/SettingsPage'
import { abilityAccessCtrl, common, ConfigurationConstant } from '@kit.AbilityKit'
import { checkPermissionGrant, requestPermissionsFromUser } from '../../util/PermissionUtils'
import { promptAction } from '@kit.ArkUI'
import { SettingsSheetViewFunctions } from './SettingsSheetView'

@Component
export struct VideoLibrarySettingsPage {
  @Prop
  @Require
  functions: SettingsSheetViewFunctions
  @Consume('pageController')
  pageController: NavPathStack
  @Consume('settingsPageController')
  settingsPageController: NavPathStack
  @StorageLink('appColorMode')
  colorMode: string = "system";
  @StorageLink('autoShutdown')
  autoShutdown: boolean = false;
  @StorageLink('statusBar')
  statusBar: boolean = false;
  @StorageLink('statusBarBatteryPercent')
  statusBarBatteryPercent: boolean = false;
  @State
  settings$continuation: boolean = false
  colorModes: string[] = ["system", "light", "dark"];
  @StorageLink('preferFFmpeg')
  preferFFmpeg: boolean = false;
  @StorageLink('hardwareDecode')
  hardwareDecode: boolean = false;
  @StorageLink('lessCovering')
  lessCovering: boolean = false;

  aboutToAppear(): void {
    checkPermissionGrant("ohos.permission.DISTRIBUTED_DATASYNC")
      .then((status: abilityAccessCtrl.GrantStatus) => {
        if (status == abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          this.settings$continuation = true
        }
        if (!PreferencesUtil.getBooleanSync("continuation", false)) {
          this.settings$continuation = false
        }
      })
  }

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
        SettingsSwitch({
          settingsTitle: $r("app.string.settings_continuation"),
          settingsTips: $r("app.string.settings_continuation_tips"),
          switchValue: this.settings$continuation,
          switchEvent: {
            action: (value: boolean) => {
              if (this.settings$continuation) {
                PreferencesUtil.putSync("continuation", false)
                this.settings$continuation = false
              } else {
                requestPermissionsFromUser(getContext(this) as common.UIAbilityContext,
                  "ohos.permission.DISTRIBUTED_DATASYNC")
                  .then((value: boolean) => {
                    if (value) {
                      PreferencesUtil.putSync("continuation", true)
                      this.settings$continuation = true
                    } else {
                      PreferencesUtil.putSync("continuation", false)
                      this.settings$continuation = false
                    }
                  })
              }
            }
          }
        })
        SettingsDivider()
        SettingsSwitch({
          settingsTitle: $r("app.string.settings_auto_shutdown"),
          settingsTips: $r("app.string.settings_auto_shutdown_tips"),
          switchValue: this.autoShutdown,
          switchEvent: {
            action: (value: boolean) => {
              if (this.autoShutdown) {
                AppStorage.setOrCreate("autoShutdown", false)
                PreferencesUtil.putSync("autoShutdown", false)
              } else {
                AppStorage.setOrCreate("autoShutdown", true)
                PreferencesUtil.putSync("autoShutdown", true)
              }
            }
          }
        })
      }

      SettingsGroup() {
        SettingsRow({
          settingsTitle: $r("app.string.settings_toolbar"),
          showGoToIcon: true,
          clickEvent: {
            action: () => {
              this.settingsPageController.pushPath({
                name: 'toolbarCustomization'
              })
            }
          }
        })
        SettingsDivider()
        SettingsSwitch({
          settingsTitle: $r("app.string.settings_less_covering"),
          settingsTips: $r("app.string.settings_less_covering_tips"),
          switchValue: this.lessCovering,
          switchEvent: {
            action: (value: boolean) => {
              if (this.lessCovering) {
                AppStorage.setOrCreate("lessCovering", false)
                PreferencesUtil.putSync("lessCovering", false)
              } else {
                AppStorage.setOrCreate("lessCovering", true)
                PreferencesUtil.putSync("lessCovering", true)
              }
            }
          }
        })
        SettingsDivider()
        SettingsSwitch({
          settingsTitle: $r("app.string.settings_status_bar"),
          settingsTips: $r("app.string.settings_status_bar_desc"),
          switchValue: this.statusBar,
          switchEvent: {
            action: (value: boolean) => {
              if (this.statusBar) {
                AppStorage.setOrCreate("statusBar", false)
                PreferencesUtil.putSync("statusBar", false)
              } else {
                AppStorage.setOrCreate("statusBar", true)
                PreferencesUtil.putSync("statusBar", true)
              }
            }
          }
        })
        if (this.statusBar) {
          Column() {
            SettingsDivider()
            SettingsSwitch({
              settingsTitle: $r("app.string.settings_status_bar_battery_percent"),
              settingsTips: $r("app.string.settings_status_bar_battery_percent_tips"),
              switchValue: this.statusBarBatteryPercent,
              switchEvent: {
                action: (value: boolean) => {
                  if (this.statusBarBatteryPercent) {
                    AppStorage.setOrCreate("statusBarBatteryPercent", false)
                    PreferencesUtil.putSync("statusBarBatteryPercent", false)
                  } else {
                    AppStorage.setOrCreate("statusBarBatteryPercent", true)
                    PreferencesUtil.putSync("statusBarBatteryPercent", true)
                  }
                }
              }
            })
          }
          .visibility(this.statusBar ? Visibility.Visible : Visibility.Hidden)
        }
      }

      SettingsGroup() {
        SettingsSelection({
          settingsTitle: $r("app.string.settings_prefered_player"),
          settingsTips: $r("app.string.settings_prefered_player_tips"),
          blankSize: 3,
          choices: [
            {
              title: "IJK",
              onSwitch: () => {
                this.preferFFmpeg = true
                AppStorage.setOrCreate("preferFFmpeg", true)
                PreferencesUtil.putSync("preferFFmpeg", true)
              }
            },
            {
              title: "AV",
              onSwitch: () => {
                this.preferFFmpeg = false
                AppStorage.setOrCreate("preferFFmpeg", false)
                PreferencesUtil.putSync("preferFFmpeg", false)
              }
            }
          ],
          selectedButton: this.preferFFmpeg ? 0 : 1
        })
        if (this.preferFFmpeg) {
          Column() {
            SettingsDivider()
            SettingsSwitch({
              settingsTitle: $r("app.string.settings_hardware_decode"),
              settingsTips: $r("app.string.settings_hardware_decode_tips"),
              switchValue: this.hardwareDecode,
              switchEvent: {
                action: (value: boolean) => {
                  this.hardwareDecode = value
                  AppStorage.setOrCreate("hardwareDecode", value)
                  PreferencesUtil.putSync("hardwareDecode", value)
                }
              }
            })
          }
          .visibility(this.preferFFmpeg ? Visibility.Visible : Visibility.Hidden)
        }
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
              this.functions.onClose()
            }
          }
        })
      }
    }
  }
}
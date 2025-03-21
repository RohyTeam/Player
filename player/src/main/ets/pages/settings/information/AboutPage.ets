import BuildProfile from 'BuildProfile'
import { getIcon } from '../../../util/IconUtil'
import { SettingsGroup, SettingsPage, SettingsRow } from '../../components/SettingsPage'
import { promptAction } from '@kit.ArkUI'

@Component
export struct AboutPage {
  @Consume('settingsPageController')
  settingsPageController: NavPathStack
  @StorageLink("debugMode")
  private debugMode: boolean = false
  @State
  private counter: number = 0

  build() {
    NavDestination() {
      Row() {
        Button({
          type: ButtonType.Circle
        }) {
          SymbolGlyph($r("sys.symbol.chevron_left"))
            .fontSize(24)
            .fontColor([$r("app.color.icon_primary")])
        }
        .onClick(() => {
          this.settingsPageController.pop()
        })
        .align(Alignment.Center)
        .margin({
          left: 12,
          top: 12
        })
        .width(40)
        .height(40)
        .backgroundColor($r("app.color.comp_background_tertiary"))

        Text($r('app.string.about'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.font_primary"))
          .margin({
            left: 12,
            top: 12,
          })
        Blank()
          .layoutWeight(1)
      }
      .margin({
        left: 12,
        right: 12,
        top: 12
      })

      Column() {
        Blank()
          .height(20)
          .width("100%")
      }

      // 内容
      Column() {
        Image(getIcon($r("app.media.drawable")))
          .width("72vp")
          .height("72vp")
          .margin({
            bottom: 8
          })
          .border({
            width: 1,
            radius: 20,
            color: $r("app.color.icon_fourth")
          })
        Text($r("app.string.PlayerAbility_label"))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Blank()
          .height(32)
        SettingsPage() {
          SettingsGroup() {
            SettingsRow({
              settingsTitle: $r('app.string.version_info'),
              settingsDesc: BuildProfile.VERSION_NAME,
              larger: true,
              clickEvent: {
                action: () => {
                  if (!this.debugMode) {
                    this.counter += 1
                    if (this.counter == 5) {
                      promptAction.showToast({
                        message: $r('app.string.debug_mode_activate'),
                      })
                      AppStorage.setOrCreate("debugMode", true)
                    }
                  }
                }
              }
            })
          }
        }
      }
      .alignItems(HorizontalAlign.Center)
      .width("100%")
      .height("100%")
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.rohy_settings_background"))
  }
}
import { Pref } from '../../../context/PreferenceContext'
import { InnerButton } from '../../component/inner/InnerButton'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { InnerSwitch } from '../../component/inner/InnerSwitch'
import { InnerDivider } from '../../component/inner/InnerDivider'
import { openUrl } from '../../../utils/AbilityUtils'

@ComponentV2
export struct SettingsSheet {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Consumer("sheetNavigator")
  private sheetNavigator: NavPathStack = new NavPathStack()
  @Event
  close: () => void

  build() {
    InnerContainer({
      bgColor: Color.Transparent,
      fillHeight: true
    }) {
      /*
      InnerComponentSet() {
        InnerSwitch({
          title: $r("app.string.continuation"),
          popup: $r("app.string.continuation_tips"),
          switch: (original) => {
            return !original
          }
        })
      }
      InnerContainerDivider()
      */
      InnerComponentSet() {
        // ComponentV2 现在还不支持 WithTheme，先屏蔽这个设置项
        /*InnerSegment({
          title: $r("app.string.color_mode"),
          initialSelected: Pref.colorMode,
          choices: [
            {
              title: $r("app.string.color_mode_system"),
              action: () => {
                Pref.colorMode = ThemeColorMode.SYSTEM
                // setColorMode(this.getUIContext(), ThemeColorMode.SYSTEM)
              }
            },
            {
              title: $r("app.string.color_mode_light"),
              action: () => {
                Pref.colorMode = ThemeColorMode.LIGHT
                // setColorMode(this.getUIContext(), ThemeColorMode.LIGHT)
              }
            },
            {
              title: $r("app.string.color_mode_dark"),
              action: () => {
                Pref.colorMode = ThemeColorMode.DARK
                // setColorMode(this.getUIContext(), ThemeColorMode.DARK)
              }
            }
          ]
        })
        InnerDivider()*/
        InnerButton({
          title: $r("app.string.appearance"),
          showGoToIcon: true,
          clickCallback: () => {
            this.sheetNavigator.pushPath({ name: "appearance" })
          }
        })
      }

      InnerContainerDivider()
      InnerComponentSet() {
        InnerSwitch({
          title: $r("app.string.screen_forward_and_backward"),
          popup: $r("app.string.screen_forward_and_backward_tips"),
          initialValue: Pref.screenForwardAndBackward,
          switch: (original) => {
            Pref.screenForwardAndBackward = !original
            return !original
          }
        })
        InnerDivider()
        InnerSwitch({
          title: $r("app.string.hardware_decode"),
          popup: $r("app.string.hardware_decode_tips"),
          initialValue: Pref.hardwareDecoding,
          switch: (original) => {
            Pref.hardwareDecoding = !original
            return !original
          }
        })
      }

      // 还没做，先屏蔽，等 PC 功能完成后一并添加
      /*InnerContainerDivider()
      InnerComponentSet() {
        InnerButton({
          title: $r("app.string.font_management"),
          showGoToIcon: true,
          clickCallback: () => {
          }
        })
      }*/

      InnerContainerDivider()
      InnerComponentSet() {
        InnerButton({
          title: $r("app.string.questions"),
          showGoToIcon: true,
          clickCallback: () => {
            this.sheetNavigator.pushPath({ name: "qna" })
          }
        })
        InnerDivider()
        InnerButton({
          title: $r("app.string.privacy_policy"),
          showGoToIcon: true,
          clickCallback: () => {
            openUrl(this.getUIContext(), "https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1770139877623479680")
          }
        })
        InnerDivider()
        InnerButton({
          title: $r("app.string.update_log"),
          showGoToIcon: true,
          clickCallback: () => {
            this.sheetNavigator.pushPath({ name: "update_log" })
          }
        })
        InnerDivider()
        InnerButton({
          title: $r("app.string.about"),
          showGoToIcon: true,
          clickCallback: () => {
            this.sheetNavigator.pushPath({ name: "about" })
          }
        })
      }

      /*
            InnerContainerDivider()
            InnerComponentSet() {
              InnerButton({
                title: "debug",
                showGoToIcon: true,
                clickCallback: () => {
                  this.close()
                  this.indexNavigator.pushPath({ name: 'DebugPage' })
                }
              })
            }*/
    }
  }
}
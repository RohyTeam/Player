import { Pref, PreferenceContext } from '../../../context/PreferenceContext'
import { InnerButton } from '../../component/inner/InnerButton'
import { InnerSegment } from '../../component/inner/InnerSegment'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { AppStorageV2 } from '@kit.ArkUI'
import { InnerSwitch } from '../../component/inner/InnerSwitch'
import { InnerDivider } from '../../component/inner/InnerDivider'
import { setColorMode } from '../../../utils/ConfigurationUtils'

@ComponentV2
export struct SettingsSheet {
  @Event
  close: () => void = () => {
  }

  build() {
    InnerContainer({
      bgColor: Color.Transparent
    }) {
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
      InnerComponentSet() {
        InnerSegment({
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
        InnerDivider()
        InnerButton({
          title: $r("app.string.blur_effect"),
          showGoToIcon: true,
          clickCallback: () => {
          }
        })
        InnerDivider()
        InnerSwitch({
          title: $r("app.string.less_cover"),
          popup: $r("app.string.less_cover_tips"),
          switch: (original) => {
            return !original
          }
        })
      }

      InnerContainerDivider()
      InnerComponentSet() {
        InnerSwitch({
          title: $r("app.string.hardware_decode"),
          popup: $r("app.string.hardware_decode_tips"),
          switch: (original) => {
            return !original
          }
        })
      }

      InnerContainerDivider()
      InnerComponentSet() {
        InnerButton({
          title: $r("app.string.font_management"),
          showGoToIcon: true,
          clickCallback: () => {
          }
        })
      }

      InnerContainerDivider()
      InnerComponentSet() {
        InnerButton({
          title: $r("app.string.questions"),
          showGoToIcon: true,
          clickCallback: () => {
          }
        })
        InnerDivider()
        InnerButton({
          title: $r("app.string.about"),
          showGoToIcon: true,
          clickCallback: () => {
          }
        })
      }
    }
  }
}
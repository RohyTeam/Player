import { PlayerContext } from "../../../player/PlayerContext"
import { InnerComponentSet } from "../../component/inner/InnerComponentSet"
import { InnerContainer } from "../../component/inner/InnerContainer"
import { InnerContainerDivider } from "../../component/inner/InnerContainerDivider"
import { InnerCounter } from "../../component/inner/InnerCounter"
import { InnerDivider } from "../../component/inner/InnerDivider"
import { InnerSwitch } from "../../component/inner/InnerSwitch"

@ComponentV2
export struct VisualEffectSheet {

  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  @Event
  hideChooser: () => void = () => {
  }

  build() {
    InnerContainer({
      bgColor: Color.Transparent,
      edgeEffect: false,
      staticBottomAvoid: false
    }) {
      InnerComponentSet() {
        InnerCounter({
          title: $r("app.string.grayscale"),
          min: 0,
          max: 100,
          step: 1,
          initialValue: this.playerContext.visualEffect_grayscale,
          resetValue: 0,
          onChange: (value) => {
            this.playerContext.visualEffect_grayscale = value
          }
        })
        InnerDivider()
        InnerCounter({
          title: $r("app.string.brightness"),
          min: -100,
          max: 100,
          step: 1,
          initialValue: this.playerContext.visualEffect_brightness,
          resetValue: 0,
          onChange: (value) => {
            this.playerContext.visualEffect_brightness = value
          }
        })
        InnerDivider()
        InnerCounter({
          title: $r("app.string.saturate"),
          min: -100,
          max: 500,
          step: 1,
          initialValue: this.playerContext.visualEffect_saturate,
          resetValue: 0,
          onChange: (value) => {
            this.playerContext.visualEffect_saturate = value
          }
        })
        InnerDivider()
        InnerCounter({
          title: $r("app.string.contrast"),
          min: -100,
          max: 500,
          step: 1,
          initialValue: this.playerContext.visualEffect_contrast,
          resetValue: 0,
          onChange: (value) => {
            this.playerContext.visualEffect_contrast = value
          }
        })
        InnerDivider()
        InnerSwitch({
          title: $r("app.string.invert"),
          initialValue: this.playerContext.visualEffect_invert,
          switch: (original) => {
            this.playerContext.visualEffect_invert = !original
            return !original
          }
        })
      }
      InnerContainerDivider()
    }
  }

}
import { PlayerContext } from "../../../../player/PlayerContext"
import { buildMenuGroup, menuGroups, RohyMenu, RohyMenuItem } from "../../../component/menu/RohyMenu"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { PlayerController } from "../../../../player/PlayerController"
import { CircleIconButton } from "../../../button/CircleIconButton"
import { ControllerClickButton, ControllerMenuButton } from "../ControllerItems"
import { InnerContainer } from "../../../component/inner/InnerContainer"
import { InnerComponentSet } from "../../../component/inner/InnerComponentSet"
import { InnerCounter } from "../../../component/inner/InnerCounter"
import { InnerDivider } from "../../../component/inner/InnerDivider"
import { InnerSwitch } from "../../../component/inner/InnerSwitch"
import { InnerContainerDivider } from "../../../component/inner/InnerContainerDivider"
import { ControlsContext } from "../../PlayerBottomBar"
import { InnerSegment } from "../../../component/inner/InnerSegment"

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
        InnerSegment({
          title: $r("app.string.rotation"),
          initialSelected: this.playerContext.visualEffect_rotation / 90,
          choices: [
            {
              title: "0°",
              action: () => {
                this.playerContext.visualEffect_rotation = 0
              }
            },
            {
              title: "90°",
              action: () => {
                this.playerContext.visualEffect_rotation = 90
              }
            },
            {
              title: "180°",
              action: () => {
                this.playerContext.visualEffect_rotation = 180
              }
            },
            {
              title: "270°",
              action: () => {
                this.playerContext.visualEffect_rotation = 270
              }
            }
          ]
        })
        InnerDivider()
        InnerCounter({
          title: $r("app.string.grayscale"),
          min: 0,
          max: 100,
          step: 1,
          initialValue: this.playerContext.visualEffect_grayscale,
          resetValue: 0,
          gestureAlwaysAnnouncement: true,
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
          gestureAlwaysAnnouncement: true,
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
          gestureAlwaysAnnouncement: true,
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
          gestureAlwaysAnnouncement: true,
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

@ComponentV2
struct ControllerVideoFiltersMenuItem {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  @Consumer("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()

  build() {
    MenuItem({
      symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.camera_filters")),
      content: $r("app.string.visual_effect")
    })
      .onClick(() => {
        this.controlsContext.showFilterSheet = true
      })
  }

}

@ComponentV2
struct ControllerVideoFiltersButton {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  @Consumer("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()

  @Param
  @Require
  buttonMargin: Margin = {}

  build() {
    ControllerClickButton({
      icon: $r("sys.symbol.camera_filters"),
      buttonMargin: this.buttonMargin,
      click: () => {
        this.controlsContext.showFilterSheet = true
      }
    })
  }

}

@Builder
export function videoFiltersMenuItem() {
  MenuItem() {
    ControllerVideoFiltersMenuItem()
  }
}

@Builder
export function videoFiltersButton(margin: Margin) {
  ControllerVideoFiltersButton({
    buttonMargin: margin
  })
}
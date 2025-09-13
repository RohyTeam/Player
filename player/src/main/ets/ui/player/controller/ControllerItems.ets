import { PlayerContext } from "../../../player/PlayerContext"
import { PlayerController } from "../../../player/PlayerController"
import { CircleIconButton } from "../../button/CircleIconButton"
import { CircleIconSwitch } from "../../button/CircleIconSwitch"

@ComponentV2
export struct ControllerMenuButton {

  @Param
  @Require
  icon: Resource
  @Param
  isSymbol: boolean = true
  @Param
  buttonMargin: Margin = {}

  @Local
  private show: boolean = false

  @BuilderParam
  menu: () => void

  build() {
    CircleIconButton({
      icon: this.icon,
      isSymbol: this.isSymbol,
      buttonMargin: this.buttonMargin,
      clickCallback: () => {
        this.show = false // refresh menu status
        this.show = true
      }
    })
      .bindMenu(this.show!!, this.menu, {
        onDisappear: () => {
          this.show = false
        }
      })
  }

}

@ComponentV2
export struct ControllerSwitchButton {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  @Param
  @Require
  icon: Resource
  @Param
  isSymbol: boolean = true
  @Param
  buttonMargin: Margin = {}

  @Event
  switch: (value: boolean, context: PlayerContext, controller: PlayerController) => boolean

  build() {
    CircleIconSwitch({
      icon: this.icon,
      isSymbol: this.isSymbol,
      buttonMargin: this.buttonMargin,
      switch: (value) => {
        return this.switch(value, this.playerContext, this.playerController)
      }
    })
  }

}

@ComponentV2
export struct ControllerClickButton {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  @Param
  @Require
  icon: Resource
  @Param
  isSymbol: boolean = true
  @Param
  buttonMargin: Margin = {}

  @Event
  click: (context: PlayerContext, controller: PlayerController) => void

  build() {
    CircleIconButton({
      icon: this.icon,
      isSymbol: this.isSymbol,
      buttonMargin: this.buttonMargin,
      clickCallback: () => {
        this.click(this.playerContext, this.playerController)
      }
    })
  }

}
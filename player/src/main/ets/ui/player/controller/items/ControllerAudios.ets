import { PlayerContext } from "../../../../player/PlayerContext"
import { buildMenuGroup, menuGroups, RohyMenu, RohyMenuItem } from "../../../component/menu/RohyMenu"
import { SymbolGlyphModifier } from "@kit.ArkUI"
import { PlayerController } from "../../../../player/PlayerController"
import { CircleIconButton } from "../../../button/CircleIconButton"
import { ControllerMenuButton } from "../ControllerItems"

@ComponentV2
struct ControllerAudios {

  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  build() {
    RohyMenu({
      groups: menuGroups(() => [
        buildMenuGroup(() => {
          let items: RohyMenuItem[] = []
          this.playerContext.audios.forEach((audio, index) => {
            items.push({
              options: {
                startIcon: audio.codec === "av3a" ? $r('app.media.vivid_gold_icon') : undefined,
                content: audio.title,
                symbolEndIcon: this.playerContext.selectedAudio === index ?
                  new SymbolGlyphModifier($r("sys.symbol.checkmark")) : undefined
              },
              action: () => {
                if (this.playerContext.selectedAudio == index) {
                  return
                }

                let deselect = this.playerContext.audios[this.playerContext.selectedAudio].index
                this.playerContext.selectedAudio = index

                let paused = this.playerContext.paused
                if (!paused) {
                  this.playerController.pause()
                }
                this.playerController.deselectTrack(deselect)
                this.playerController.selectTrack(audio.index)
                this.playerController.seek(this.playerContext.currentPosition)
                if (!paused) {
                  this.playerController.play()
                }
              }
            })
          })
          return items
        })
      ])
    })
  }

}

@Builder
function audiosMenu() {
  ControllerAudios()
}

@Builder
export function audiosMenuItem() {
  MenuItem() {
    MenuItem({
      symbolStartIcon: new SymbolGlyphModifier($r("sys.symbol.sound")),
      content: $r("app.string.audios"),
      builder: audiosMenu
    })
  }
}

@Builder
export function audiosButton(margin: Margin) {
  ControllerMenuButton({
    icon: $r("sys.symbol.sound"),
    buttonMargin: margin
  }) {
    audiosMenu()
  }
}
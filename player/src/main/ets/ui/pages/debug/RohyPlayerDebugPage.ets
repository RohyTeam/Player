import RohyPlayer from "librohy_player.so"
import { ensurePath } from "../../../utils/FileUtils"
import { pickSingleVideoFile } from "../../../utils/PickerUtils"

@ComponentV2
export struct RohyPlayerDebugPage {
  build() {
    NavDestination() {
      Column() {
        Blank()
          .layoutWeight(1)
        XComponent({
          id: "rohyplayer_test",
          type: XComponentType.SURFACE,
          libraryname: "rohy_player",
        })
          .onLoad(() => {
            pickSingleVideoFile(this.getUIContext())
              .then((url) => {
                if (!url)
                  return
                RohyPlayer.RohyPlayer_test("rohyplayer_test", ensurePath(url))
              })
              .catch((err: Error) => {
                console.error(`FUCK! error occurs: ${err.message}: ${err.stack}`)
              })
          })
          .width("100%")
          .aspectRatio(16 / 9)
        Blank()
          .layoutWeight(1)
      }
      .width("100%")
      .height("100%")
    }
    .backgroundColor($r("app.color.rohy_background"))
    .hideTitleBar(false)
    .hideToolBar(true)
    .hideBackButton(false)
    .title("rohy player test")
    .width("100%")
    .height("100%")
  }

}
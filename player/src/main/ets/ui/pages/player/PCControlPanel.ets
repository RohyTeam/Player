import { Sys } from "../../../context/SystemContext"
import { PlayerBottomBar } from "./PlayerBottomBar"
import { curves } from "@kit.ArkUI"
import { uniformTypeDescriptor } from "@kit.ArkData"
import { Dialoger } from "../../dialog/Dialoger"
import { pickSingleVideoFile, saveJpgFile } from "../../../utils/PickerUtils"
import RohyPlayer from "libplayer.so"
import { fileUri } from "@kit.CoreFileKit"
import { JSON } from "@kit.ArkTS"
import { VideoMetadata } from "../../../metadata/VideoMetadata"
import { PlayerContext } from "../../../player/PlayerContext"
import { AbilityStorage } from "../../../storage/AbilityStorage"
import { LocalFileVideoSource } from "../../../player/VideoSource"
import { PlayerController } from "../../../player/PlayerController"
import { MetadataCache } from "../../../cache/MetadataCache"

@ComponentV2
export struct PCControlPanel {

  @Local
  lastMovingMouse: number = 0
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Consumer("showSidebar")
  showSidebar: boolean = false
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  build() {
    Column() {
      Blank()
        .bindContextMenu(
          this.RightClickContextMenu,
          ResponseType.RightClick
        )
        .bindContextMenu(
          this.RightClickContextMenu,
          ResponseType.LongPress // for PC touching feature
        )
        .allowDrop([uniformTypeDescriptor.UniformDataType.VIDEO])
        .onDrop((event, params) => {
          Dialoger.alert(this.getUIContext(), undefined, "当前还未支持拖拽播放")
          // TODO: check if the uri is in a public directory so that we can actually play it
          /*
          if (event.getData().getRecords().length != 1) {
            Dialoger.alert(this.getUIContext(), undefined, "一次只能播放一个文件")
            return
          }
          let record = event.getData().getRecords()[0]
          let fileInfo = record.getEntry(uniformTypeDescriptor.UniformDataType.FILE_URI) as uniformDataStruct.FileUri
          let path = fileUri.getUriFromPath(fileInfo.oriUri)
          */
        })
        .layoutWeight(1)
      PlayerBottomBar()
        .visibility((Sys.time - this.lastMovingMouse < 3 * 1000) || this.showSidebar ? Visibility.Visible : Visibility.Hidden)
        .animation({
          curve: curves.springMotion(),
          duration: 200
        })
        .transition(
          TransitionEffect.asymmetric(
            TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY),
            TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY)
          )
        )
    }
    .onMouse(() => {
      animateTo({}, () => {
        this.lastMovingMouse = Date.now()
      })
    })
    .width("100%")
    .height("100%")
  }

  @Builder
  private RightClickContextMenu() {
    Menu() {
      MenuItemGroup() {
        MenuItem({ content: $r('app.string.context_menu_open') })
          .onClick(() => {
            this.playerController.release()
            pickSingleVideoFile(this.getUIContext())
              .then((path) => {
                if (path == undefined) {
                  console.error(`metadata path: ${path}`)
                  return
                }
                let metadata = MetadataCache.getOrCreate(path)
                this.playerContext.video = true
                this.playerContext.videoSource = new LocalFileVideoSource(
                  metadata,
                  path
                )
              })
          })
        if (this.playerContext.video) {
          MenuItem({ content: $r('app.string.context_menu_open_subtitle') })
            .onClick(() => {
              // todo
            })
          MenuItem({ content: $r('app.string.context_menu_close_file') })
            .onClick(() => {
              this.playerController.release()
            })
        }
      }
      MenuItemGroup() {
        MenuItem({ content: $r("app.string.context_menu_settings") })
          .onClick(() => {
            // todo
          })
      }
    }
  }

}
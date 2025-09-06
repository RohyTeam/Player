import { Sys } from '../../../context/SystemContext'
import { PlayerBottomBar } from '../PlayerBottomBar'
import { curves } from '@kit.ArkUI'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { Dialoger } from '../../dialog/Dialoger'
import { pickSingleVideoFile } from '../../../utils/PickerUtils'
import { fileUri } from '@kit.CoreFileKit'
import { PlayerContext } from '../../../player/PlayerContext'
import { AbilityStorage } from '../../../storage/AbilityStorage'
import { LocalFileVideoSource } from '../../../player/VideoSource'
import { PlayerController } from '../../../player/PlayerController'
import { MetadataFetcher } from '../../../metadata/MetadataFetcher'
import { buildMenuGroup, menuGroups, RohyMenu, RohyMenuItem } from '../../component/menu/RohyMenu'
import { ensureUIAbilityContext } from '../../../utils/AbilityUtils'
import { SavedVideoMetadata } from '../../../metadata/SavedVideoMetadata'
import { VideoMetadataManager } from '../../../metadata/VideoMetadataManager'
import { sha256 } from '../../../utils/HashUtils'
import { ensurePath } from '../../../utils/FileUtils'

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
        .focusable(false)
        .visibility((Sys.time - this.lastMovingMouse < 3 * 1000) || this.showSidebar ? Visibility.Visible :
        Visibility.Hidden)
        .animation({
          curve: curves.springMotion(),
          duration: 200
        })
        .transition(TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY))
    }
    .focusable(false)
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
    RohyMenu({
      groups: menuGroups(() => [
        buildMenuGroup(() => {
          let items: RohyMenuItem[] = []

          items.push({
            options: {
              content: $r('app.string.context_menu_open')
            },
            action: () => {
              this.playerController.release()
              pickSingleVideoFile(this.getUIContext())
                .then(async (url) => {
                  if (!url) {
                    return
                  }
                  if (url.startsWith("file://media")) {
                    Dialoger.alert(this.getUIContext(), "请不要用文件浏览器打开图库文件", undefined)
                    return
                  }
                  let savedMetadata: SavedVideoMetadata
                  if (VideoMetadataManager.exists(sha256(`files:${url}`))) {
                    savedMetadata = VideoMetadataManager.load(sha256(`files:${url}`))!
                  } else {
                    // TODO: 用全新的 SendableVideoMetadataManager 来异步保存数据
                    let metadata = await MetadataFetcher.fetch(ensurePath(url), url.startsWith("files://media"))
                    savedMetadata = VideoMetadataManager.save(
                      sha256(`files:${url}`),
                      false,
                      url,
                      metadata
                    )!
                  }
                  this.playerContext.video = true
                  this.playerContext.videoSource = new LocalFileVideoSource(
                    false,
                    savedMetadata,
                    url,
                    new fileUri.FileUri(url).name
                  )
                })
            }
          })

          if (this.playerContext.video) {
            items.push({
              options: {
                content: $r('app.string.context_menu_close_file')
              },
              action: () => {
                this.playerController.release()
              }
            })
          }

          return items
        }),
        buildMenuGroup(() => [
          {
            options: {
              content: $r("app.string.context_menu_settings")
            },
            action: () => {
              // todo
            }
          },
          {
            options: {
              content: $r("app.string.exit")
            },
            action: () => {
              this.playerController.release()
              ensureUIAbilityContext(this.getUIContext()).terminateSelf()
            }
          }
        ])
      ])
    })
  }
}
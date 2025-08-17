import { PlaylistDao } from "../../../../database/dao/PlaylistDao"
import { emptyPlaylistStructure,
  isPlaylistFolder,
  PlaylistFolder,
  PlaylistItem,
  PlaylistStructure,
  PlaylistVideo,
  sortPlaylistItems} from "../../../../playlist/PlaylistStructure"
import { JSON } from "@kit.ArkTS"
import { PlaylistMenuButtons } from "./PlaylistMenuButtons"
import { PlaylistFolderItemsDataSource } from "../../../../datasource/playlist/PlaylistFolderItemsDataSource"
import { SimpleLoadingPage } from "../../../component/page/SimpleLoadingPage"
import { Modifiers } from "../../../attributemodifier/Modifiers"
import { curves } from "@kit.ArkUI"
import { PlaylistVideoItem } from "./PlaylistVideoItem"
import { PlaylistFolderItem } from "./PlaylistFolderItem"

@ComponentV2
export struct PlaylistFolderView {

  @Param
  @Require
  data: PlaylistDao
  @Param
  @Require
  path: number[]

  @Provider("structure")
  structure: PlaylistStructure = emptyPlaylistStructure()

  @Provider("folder")
  folder?: PlaylistFolder

  @Provider("playlistFolderDataSource")
  playlistFolderDataSource?: PlaylistFolderItemsDataSource

  aboutToAppear(): void {
    this.structure = JSON.parse(this.data.structure) as PlaylistStructure
    let folder: PlaylistFolder | undefined = undefined
    for (let index of this.path) {
      if (folder == undefined) {
        folder = sortPlaylistItems(this.structure.items)[index] as PlaylistFolder
        continue
      }
      folder = sortPlaylistItems(folder.items)[index] as PlaylistFolder
    }
    this.folder = folder
    this.playlistFolderDataSource = new PlaylistFolderItemsDataSource(this.data, this.structure, this.folder)
  }

  build() {
    NavDestination() {
      if (this.playlistFolderDataSource) {
        Grid(undefined, { regularSize: [1, 1] }) {
          LazyForEach(this.playlistFolderDataSource, (playlistItem: PlaylistItem) => {
            GridItem() {
              if (isPlaylistFolder(playlistItem)) {
                PlaylistFolderItem({
                  data: this.data,
                  path: this.path,
                  folderItem: playlistItem as PlaylistFolder
                })
              } else {
                PlaylistVideoItem({
                  video: playlistItem as PlaylistVideo
                })
              }
            }
            .transition(
              TransitionEffect.OPACITY
                .combine(
                  TransitionEffect.scale({
                    x: 0.7,
                    y: 0.7
                  })
                )
                .animation({
                  duration: 200,
                  curve: curves.springMotion()
                })
            )
          })
        }
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .attributeModifier(Modifiers.gridLayout(this.getUIContext()))
        .padding({
          left: "5%",
          right: "5%",
        })
        .rowsGap(8)
        .columnsGap(8)
        .layoutDirection(GridDirection.Row)
        .width("100%")
        .height("100%")
      } else {
        SimpleLoadingPage()
      }
    }
    .title(this.folderTitle())
    .menus(this.menuButtons)
    .backgroundColor($r("app.color.rohy_background"))
    .hideTitleBar(false)
    .hideToolBar(true)
    .hideBackButton(false)
    .width("100%")
    .height("100%")
  }

  @Builder
  private menuButtons() {
    PlaylistMenuButtons()
  }

  private folderTitle(): string {
    if (this.folder) {
      return this.folder.name
    } else {
      return this.data.name
    }
  }

}
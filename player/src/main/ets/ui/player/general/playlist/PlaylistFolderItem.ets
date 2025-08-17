import { PlaylistDao } from "../../../../database/dao/PlaylistDao"
import { emptyPlaylistStructure, PlaylistFolder,
  PlaylistItem,
  PlaylistStructure,
  sortPlaylistItems} from "../../../../playlist/PlaylistStructure"

@ComponentV2
export struct PlaylistFolderItem {

  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  @Consumer("structure")
  structure: PlaylistStructure = emptyPlaylistStructure()

  @Consumer("folder")
  folder?: PlaylistFolder

  @Param
  @Require
  data: PlaylistDao
  @Param
  @Require
  path: number[]
  @Param
  @Require
  folderItem: PlaylistFolder

  build() {
    Button() {
      Column() {
        Image($r("app.media.hidisk_icon_folder"))
          .aspectRatio(4 / 3)
          .width("100%")
          .margin({
            top: 8,
            left: 8,
            right: 8,
            bottom: 4
          })
        Text(this.folderItem.name)
          .margin({
            bottom: 8,
            left: 8,
            right: 8
          })
      }
    }
    .onClick(() => {
      let params: Record<string, object> = {
        'dao': this.data,
        'path': this.subDir(this.folderItem)
      }
      this.indexNavigator.pushPath({ name: `PlaylistView`, param: params })
    })
    .borderRadius(16)
    .type(ButtonType.Normal)
    .backgroundColor(Color.Transparent)
  }

  private subDir(playlistItem: PlaylistItem): number[] {
    let newPath: number[] = []
    newPath.push(...this.path)
    newPath.push(this.folderItems().findIndex((it) => it.name == playlistItem.name))
    return newPath
  }

  private folderItems(): PlaylistItem[] {
    if (this.folder) {
      return sortPlaylistItems(this.folder.items)
    } else {
      return sortPlaylistItems(this.structure.items)
    }
  }

}
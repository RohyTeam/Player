import { PlaylistDao } from "../../database/dao/PlaylistDao"
import { DB } from "../../database/DatabaseManager";
import { PlaylistFolder, PlaylistItem, PlaylistStructure, PlaylistVideo,
  sortPlaylistItems } from "../../playlist/PlaylistStructure";
import { JSON } from "@kit.ArkTS";


export class PlaylistFolderItemsDataSource implements IDataSource {

  private data: PlaylistDao
  private structure: PlaylistStructure
  private folder?: PlaylistFolder

  private dataChangeListeners: DataChangeListener[] = []

  constructor(data: PlaylistDao, structure: PlaylistStructure, folder?: PlaylistFolder) {
    this.data = data
    this.structure = structure
    this.folder = folder
  }

  items(): PlaylistItem[] {
    let items: PlaylistItem[]
    if (this.folder)
      items = this.folder.items
    else
      items = this.structure.items
    return sortPlaylistItems(items)
  }

  createFolder(name: string) {
    if (this.items().find((it) => it.name == name))
      return
    let newFolder: PlaylistFolder = {
      name: name,
      items: []
    }
    if (this.folder)
      this.folder.items.push(newFolder)
    else
      this.structure.items.push(newFolder)

    this.data.structure = JSON.stringify(this.structure)
    DB.playlistDao.update(this.data)

    let index = this.items().findIndex((it) => it.name == name)
    this.dataChangeListeners.forEach((listener) => {
      listener.onDataAdd(index)
    })
  }

  importVideo(name: string, identity: string, url: string) {
    let finalName = name
    let duplicateNumber = 1
    if (this.items().find((it) => it.name == finalName)) {
      if (this.items().find((it) => it.name == `${finalName}（${duplicateNumber}）`)) {
        while (this.items().find((it) => it.name == `${finalName}（${duplicateNumber}）`))
          duplicateNumber += 1

      }
      finalName = `${finalName}（${duplicateNumber}）`
    }
    let newVideo: PlaylistVideo = {
      name: finalName,
      identity: identity,
      url: url,
      played: 0
    }
    if (this.folder)
      this.folder.items.push(newVideo)
    else
      this.structure.items.push(newVideo)

    this.data.structure = JSON.stringify(this.structure)
    DB.playlistDao.update(this.data)

    let index = this.items().findIndex((it) => it.name == finalName)
    this.dataChangeListeners.forEach((listener) => {
      listener.onDataAdd(index)
    })
  }

  totalCount(): number {
    return this.items().length;
  }

  getData(index: number): PlaylistItem {
    return this.items()[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.dataChangeListeners.indexOf(listener) >= 0)
      return
    this.dataChangeListeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    let index = this.dataChangeListeners.indexOf(listener)
    if (index < 0)
      return
    this.dataChangeListeners = this.dataChangeListeners.splice(index, 1)
  }

}
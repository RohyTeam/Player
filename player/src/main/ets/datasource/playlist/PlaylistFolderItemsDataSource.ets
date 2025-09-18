import { PlaylistDao } from '../../database/dao/PlaylistDao';
import { DB } from '../../database/DatabaseManager';
import {
  isPlaylistFolder,
  isPlaylistVideo,
  PlaylistFolder,
  PlaylistItem,
  PlaylistStructure,
  PlaylistVideo,
  sortPlaylistItems
} from '../../playlist/PlaylistStructure';
import { JSON } from '@kit.ArkTS';
import { PlaylistCache } from '../../cache/PlaylistCache';


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
    if (this.folder) {
      items = this.folder.items
    } else {
      items = this.structure.items
    }
    return sortPlaylistItems(items)
  }

  rename(oldName: string, newName: string) {
    if (!this.items().find((it) => it.name == oldName)) {
      return
    }
    if (this.items().find((it) => it.name == newName)) {
      return
    }

    let oldIndex = this.items().findIndex((it) => it.name === oldName)

    if (this.folder) {
      this.folder.items.find((it) => it.name === oldName)!.name = newName
    } else {
      this.structure.items.find((it) => it.name === oldName)!.name = newName
    }

    this.data.structure = JSON.stringify(this.structure)
    DB.playlistDao.update(this.data)

    let index = this.items().findIndex((it) => it.name === newName)
    this.dataChangeListeners.forEach((listener) => {
      listener.onDataDelete(oldIndex)
      listener.onDataAdd(index)
    })
  }

  createFolder(name: string) {
    if (this.items().find((it) => it.name == name)) {
      return
    }
    let newFolder: PlaylistFolder = {
      name: name,
      items: []
    }
    if (this.folder) {
      this.folder.items.push(newFolder)
    } else {
      this.structure.items.push(newFolder)
    }

    this.data.structure = JSON.stringify(this.structure)
    DB.playlistDao.update(this.data)

    let index = this.items().findIndex((it) => it.name == name)
    this.dataChangeListeners.forEach((listener) => {
      listener.onDataAdd(index)
    })
  }

  importVideo(name: string, identity: string, url: string, hash: string, size: number) {
    let finalName = name
    let duplicateNumber = 1
    if (this.items().find((it) => it.name == finalName)) {
      if (this.items().find((it) => it.name == `${finalName}（${duplicateNumber}）`)) {
        while (this.items().find((it) => it.name == `${finalName}（${duplicateNumber}）`)) {
          duplicateNumber += 1
        }
      }
      finalName = `${finalName}（${duplicateNumber}）`
    }
    let newVideo: PlaylistVideo = {
      name: finalName,
      identity: identity,
      url: url,
      hash: hash,
      size: size,
      played: 0
    }
    if (this.folder) {
      this.folder.items.push(newVideo)
    } else {
      this.structure.items.push(newVideo)
    }

    this.data.structure = JSON.stringify(this.structure)
    DB.playlistDao.update(this.data)

    if (PlaylistCache.imported[identity]) {
      PlaylistCache.imported[identity] += 1
    } else {
      PlaylistCache.imported[identity] = 1
    }

    let index = this.items().findIndex((it) => it.name == finalName)
    this.dataChangeListeners.forEach((listener) => {
      listener.onDataAdd(index)
    })
  }

  deleteFolder(name: string) {
    let removedIndex = this.items().findIndex((it) => isPlaylistFolder(it) && it.name === name)

    if (removedIndex < 0) {
      return
    }

    console.error(`structure before delete: ${JSON.stringify(this.structure)}`)

    let removedFolder: PlaylistFolder

    if (this.folder) {
      let index = this.folder.items.findIndex((it) => it.name === name)
      removedFolder = this.folder.items[index] as PlaylistFolder
      this.folder.items.splice(index, 1)
    } else {
      let index = this.structure.items.findIndex((it) => it.name === name)
      removedFolder = this.structure.items[index] as PlaylistFolder
      this.structure.items.splice(index, 1)
    }

    this.data.structure = JSON.stringify(this.structure)
    DB.playlistDao.update(this.data)

    console.error(`structure after delete: ${JSON.stringify(this.structure)}`)

    PlaylistCache.deleteVideos(removedFolder.items)
      .then(() => {
        this.dataChangeListeners.forEach((listener) => {
          listener.onDataDelete(removedIndex)
        })
      })
  }

  deleteVideo(identity: string) {
    if (!this.hasVideo(identity)) {
      return
    }

    console.error(`structure before delete: ${JSON.stringify(this.structure)}`)

    let removedIndex =
      this.items().findIndex((it) => isPlaylistVideo(it) && (it as PlaylistVideo).identity === identity)

    let removedVideo: PlaylistVideo

    if (this.folder) {
      let index =
        this.folder.items.findIndex((it) => isPlaylistVideo(it) && (it as PlaylistVideo).identity === identity)
      removedVideo = this.folder.items[index] as PlaylistVideo
      this.folder.items.splice(index, 1)
    } else {
      let index =
        this.structure.items.findIndex((it) => isPlaylistVideo(it) && (it as PlaylistVideo).identity === identity)
      removedVideo = this.structure.items[index] as PlaylistVideo
      this.structure.items.splice(index, 1)
    }

    this.data.structure = JSON.stringify(this.structure)
    DB.playlistDao.update(this.data)

    console.error(`structure after delete: ${JSON.stringify(this.structure)}`)

    PlaylistCache.deleteVideos([removedVideo])
      .then(() => {
        this.dataChangeListeners.forEach((listener) => {
          listener.onDataDelete(removedIndex)
        })
      })
      .catch((err: Error) => {
        console.error(`error when deleting videos: ${err.message}`)
      })
  }

  hasVideo(identity: string): boolean {
    return this.hasVideoInItems(identity, this.structure.items)
  }

  private hasVideoInItems(identity: string, items: (PlaylistVideo | PlaylistFolder)[]): boolean {
    for (let item of items) {
      if (isPlaylistVideo(item)) {
        if ((item as PlaylistVideo).identity === identity) {
          return true
        }
      }
    }
    for (let item of items) {
      if (isPlaylistFolder(item)) {
        if (this.hasVideoInItems(identity, (item as PlaylistFolder).items)) {
          return true
        }
      }
    }
    return false
  }

  totalCount(): number {
    return this.items().length;
  }

  getData(index: number): PlaylistItem {
    return this.items()[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.dataChangeListeners.indexOf(listener) >= 0) {
      return
    }
    this.dataChangeListeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    let index = this.dataChangeListeners.indexOf(listener)
    if (index < 0) {
      return
    }
    this.dataChangeListeners = this.dataChangeListeners.splice(index, 1)
  }
}
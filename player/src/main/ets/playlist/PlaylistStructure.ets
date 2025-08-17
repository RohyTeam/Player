import { PlaylistDao } from "../database/dao/PlaylistDao"
import { VideoMetadata } from "../metadata/VideoMetadata"

export interface PlaylistStructure {

  items: (PlaylistVideo | PlaylistFolder)[]

}

export interface PlaylistItem {

  name: string

}

export interface PlaylistVideo extends  PlaylistItem {

  url: string
  identity: string
  played: number

}

export interface PlaylistFolder extends PlaylistItem {

  items: (PlaylistVideo | PlaylistFolder)[]

}

export function emptyPlaylistStructure(): PlaylistStructure {
  return { items: [] }
}

export function isPlaylistFolder(item: PlaylistItem): boolean {
  return Object.keys(item).indexOf("items") >= 0
}

export function isPlaylistVideo(item: PlaylistItem): boolean {
  return Object.keys(item).indexOf("url") >= 0
}

export function sortPlaylistItems(items: PlaylistItem[]): PlaylistItem[] {
  let copiedArray: PlaylistItem[] = []
  copiedArray.push(...items)
  return copiedArray.sort((a, b) => {
    if (isPlaylistFolder(a) && isPlaylistVideo(b))
      return -1
    else if (isPlaylistFolder(b) && isPlaylistVideo(a))
      return 1
    return a.name.localeCompare(b.name)
  })
}
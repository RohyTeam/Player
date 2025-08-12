import { PlaylistDao } from "../../database/dao/PlaylistDao"
import { VideoMetadata } from "../../metadata/VideoMetadata"

export interface Playlist {

  structure: PlaylistFolder

}

export interface PlaylistItem {

  name: string

}

export interface PlaylistVideo extends  PlaylistItem {

  url: string
  identity: string

}

export interface PlaylistFolder extends PlaylistItem {

  items: PlaylistItem[]

}
import { ChapterMetadata } from "./ChapterMetadata"
import { TrackMetadata } from "./TrackMetadata"

export interface VideoMetadata {

  duration: number
  bitrate: number

  width: number
  height: number

  hdr: boolean

  codec: string
  codecLong: string

  cover: ArrayBuffer | undefined // jpeg

  chapters: ChapterMetadata[]
  tracks: TrackMetadata[]

}


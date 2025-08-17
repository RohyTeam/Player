import { ChapterMetadata } from './ChapterMetadata'
import { TrackMetadata } from './TrackMetadata'

export interface VideoMetadata {

  duration: number
  bitrate: number
  averageFramerate: number
  width: number
  height: number
  hdr: boolean
  codec: string
  codecLong: string
  cover: ArrayBuffer | string | undefined // jpeg, if string, point to local saved picture path

  chapters: ChapterMetadata[]
  tracks: TrackMetadata[]

}

export function copyVideoMetadata(metadata: VideoMetadata): VideoMetadata {
  return {
    duration: metadata.duration,
    bitrate: metadata.bitrate,
    averageFramerate: metadata.averageFramerate,
    width: metadata.width,
    height: metadata.height,
    hdr: metadata.hdr,
    codec: metadata.codec,
    codecLong: metadata.codecLong,
    cover: metadata.cover,
    chapters: copyChapters(metadata.chapters),
    tracks: copyTracks(metadata.tracks)
  }
}

function copyChapters(chapters: ChapterMetadata[]): ChapterMetadata[] {
  let newChapters: ChapterMetadata[] = []
  for (let chapter of chapters) {
    newChapters.push({
      title: chapter.title,
      start: chapter.start,
      end: chapter.end,
    })
  }
  return newChapters
}

function copyTracks(tracks: TrackMetadata[]): TrackMetadata[] {
  let newTracks: TrackMetadata[] = []
  for (let track of tracks) {
    newTracks.push({
      type: track.type,
      index: track.index,
      title: track.title,
      language: track.language,
      codec: track.codec,
      codecLong: track.codecLong,
      width: track.width,
      height: track.height,
      duration: track.duration,
      averageFramerate: track.averageFramerate,
      bitrate: track.bitrate,
      sampleRate: track.sampleRate,
      filename: track.filename,
      mimetype: track.mimetype,
    })
  }
  return newTracks
}
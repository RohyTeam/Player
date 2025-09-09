import { ChapterMetadata, SendableChapterMetadata, sendableChapterMetadataToNormal } from './ChapterMetadata'
import { SendableTrackMetadata, sendableTrackMetadataToNormal, TrackMetadata } from './TrackMetadata'
import { collections } from '@kit.ArkTS'
import { arrayBufferCollectionsToES5 } from '../utils/ArkTSCollectionsUtils'

export interface VideoMetadata {

  duration: number
  bitrate: number
  averageFramerate: number
  width: number
  height: number
  hdr: number // 0: not hdr, 1: dolby vision, 2: hdr vivid, 3: hdr 10+, 4: other hdrs
  codec: string
  codecLong: string
  cover: ArrayBuffer | string | undefined // jpeg, if string, point to local saved picture path

  chapters: ChapterMetadata[]
  tracks: TrackMetadata[]

}

@Sendable
export class SendableVideoMetadata {
  duration: number
  bitrate: number
  averageFramerate: number
  width: number
  height: number
  hdr: number
  codec: string
  codecLong: string
  cover: collections.ArrayBuffer | string | undefined
  chapters: collections.Array<SendableChapterMetadata>
  tracks: collections.Array<SendableTrackMetadata>

  public constructor(
    duration: number,
    bitrate: number,
    averageFramerate: number,
    width: number,
    height: number,
    hdr: number,
    codec: string,
    codecLong: string,
    cover: collections.ArrayBuffer | string | undefined,
    chapters: collections.Array<SendableChapterMetadata>,
    tracks: collections.Array<SendableTrackMetadata>
  ) {
    this.duration = duration
    this.bitrate = bitrate
    this.averageFramerate = averageFramerate
    this.width = width
    this.height = height
    this.hdr = hdr
    this.codec = codec
    this.codecLong = codecLong
    this.cover = cover
    this.chapters = chapters
    this.tracks = tracks
  }
}

export function createSendableVideoMetadata(metadata: VideoMetadata): SendableVideoMetadata {
  let cover: collections.ArrayBuffer | string | undefined
  if (metadata.cover instanceof ArrayBuffer) {
    cover = collections.Uint8Array.from(new Uint8Array(metadata.cover)).buffer
  } else {
    cover = metadata.cover
  }
  let chapters: collections.Array<SendableChapterMetadata> = new collections.Array()
  let tracks: collections.Array<SendableTrackMetadata> = new collections.Array()

  for (let chapter of metadata.chapters) {
    chapters.push(
      new SendableChapterMetadata(
        chapter.title,
        chapter.start,
        chapter.end
      )
    )
  }

  for (let track of metadata.tracks) {
    tracks.push(
      new SendableTrackMetadata(
        track.type,
        track.index,
        track.title,
        track.language,
        track.codec,
        track.codecLong,
        track.width,
        track.height,
        track.duration,
        track.averageFramerate,
        track.bitrate,
        track.hdr,
        track.sampleRate,
        track.filename,
        track.mimetype,
      )
    )
  }

  return new SendableVideoMetadata(
    metadata.duration,
    metadata.bitrate,
    metadata.averageFramerate,
    metadata.width,
    metadata.height,
    metadata.hdr,
    metadata.codec,
    metadata.codecLong,
    cover,
    chapters,
    tracks,
  )
}

export function sendableVideoMetadataToNormal(metadata: SendableVideoMetadata): VideoMetadata {
  let cover: ArrayBuffer | string | undefined = undefined
  if (metadata.cover instanceof collections.ArrayBuffer) {
    cover = arrayBufferCollectionsToES5(metadata.cover)
  } else {
    cover = metadata.cover
  }
  let chapters: ChapterMetadata[] = []
  let tracks: TrackMetadata[] = []
  for (let chapter of metadata.chapters) {
    chapters.push(sendableChapterMetadataToNormal(chapter))
  }
  for (let track of metadata.tracks) {
    tracks.push(sendableTrackMetadataToNormal(track))
  }
  return {
    duration: metadata.duration,
    bitrate: metadata.bitrate,
    averageFramerate: metadata.averageFramerate,
    width: metadata.width,
    height: metadata.height,
    hdr: metadata.hdr,
    codec: metadata.codec,
    codecLong: metadata.codecLong,
    cover: cover,
    tracks: tracks,
    chapters: chapters,
  }
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
      hdr: track.hdr,
      sampleRate: track.sampleRate,
      filename: track.filename,
      mimetype: track.mimetype,
    })
  }
  return newTracks
}
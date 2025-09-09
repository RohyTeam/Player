export interface TrackMetadata {

  // shared
  type: number // 0 for video, 1 for audio, 2 for subtitle, 3 for attachment, -1 for unknown
  index: number
  title: string | undefined
  language: string | undefined
  codec: string | undefined
  codecLong: string | undefined
  // video
  width: number | undefined
  height: number | undefined
  duration: number | undefined
  averageFramerate: number | undefined
  bitrate: number | undefined
  hdr: number | undefined // 0: not hdr, 1: dolby vision, 2: hdr vivid, 3: hdr 10+, 4: other hdrs
  // audio
  sampleRate: number | undefined
  // attachment
  filename: string | undefined
  mimetype: string | undefined

}

@Sendable
export class SendableTrackMetadata {
  type: number
  index: number
  title: string | undefined
  language: string | undefined
  codec: string | undefined
  codecLong: string | undefined
  width: number | undefined
  height: number | undefined
  duration: number | undefined
  averageFramerate: number | undefined
  bitrate: number | undefined
  hdr: number | undefined
  sampleRate: number | undefined
  filename: string | undefined
  mimetype: string | undefined

  public constructor(
    type: number,
    index: number,
    title: string | undefined,
    language: string | undefined,
    codec: string | undefined,
    codecLong: string | undefined,
    width: number | undefined,
    height: number | undefined,
    duration: number | undefined,
    averageFramerate: number | undefined,
    bitrate: number | undefined,
    hdr: number | undefined,
    sampleRate: number | undefined,
    filename: string | undefined,
    mimetype: string | undefined,
  ) {
    this.type = type
    this.index = index
    this.title = title
    this.language = language
    this.codec = codec
    this.codecLong = codecLong
    this.width = width
    this.height = height
    this.duration = duration
    this.averageFramerate = averageFramerate
    this.bitrate = bitrate
    this.hdr = hdr
    this.sampleRate = sampleRate
    this.filename = filename
    this.mimetype = mimetype
  }
}

export function sendableTrackMetadataToNormal(track: SendableTrackMetadata): TrackMetadata {
  return {
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
    mimetype: track.mimetype
  }
}
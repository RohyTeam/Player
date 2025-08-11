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
  bitrate: number | undefined
  // audio
  sampleRate: number | undefined
  // attachment
  filename: string | undefined
  mimetype: string | undefined

}
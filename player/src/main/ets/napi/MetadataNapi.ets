interface Metadata {
  tracks: Array<Track>
}

interface Track {
  type: number
  codec: number
}

interface VideoTrack extends Track {
  bit_rate: number
  width: number
  height: number
}

interface AudioTrack extends Track {
  channels: number
  frame_size: number
  sample_rate: number
}

interface SubtitleTrack extends Track {}
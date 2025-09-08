export interface Codec {

  id: string
  names: string[]
  extension: string

}

export class CodecConstants {
  public static codecs(): Codec[] {
    return [
      CodecConstants.subtitle_pgs,
      CodecConstants.subtitle_ass,
      CodecConstants.subtitle_srt,
    ]
  }

  public static readonly subtitle_pgs: Codec = {
    id: 'pgs',
    names: ["pgssub", "hdmv_pgs_subtitle"],
    extension: 'sup'
  }
  public static readonly subtitle_ass: Codec = {
    id: 'ass',
    names: ["ass", "ssa"],
    extension: 'ass'
  }
  public static readonly subtitle_srt: Codec = {
    id: 'srt',
    names: ["srt", "subrip"],
    extension: 'srt'
  }
  public static readonly subtitle_vtt: Codec = {
    id: 'vtt',
    names: ["vtt", "webvtt"],
    extension: 'vtt'
  }

  public static getCodec(name: string): Codec | undefined {
    for (let codec of CodecConstants.codecs()) {
      if (codec.names.indexOf(name) >= 0) {
        return codec
      }
    }
    return undefined
  }
}
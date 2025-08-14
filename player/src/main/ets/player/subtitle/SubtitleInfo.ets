export interface SubtitleInfo {

  readonly title: ResourceStr
  readonly language: string | undefined

  readonly url: string
  readonly type: 'ass' | 'srt' | 'pgs'

  readonly internal: boolean

}
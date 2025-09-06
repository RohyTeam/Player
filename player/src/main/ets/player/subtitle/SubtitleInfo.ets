import { lang } from "@kit.ArkTS"

export interface SubtitleInfo {

  readonly title: string | undefined
  readonly language: string | undefined
  readonly url: string
  readonly type: 'ass' | 'srt' | 'pgs'
  readonly internal: boolean

}

@Sendable
export class SendableSubtitleInfo {

  readonly title: string | undefined
  readonly language: string | undefined
  readonly url: string
  readonly type: string
  readonly internal: boolean

  public constructor(
    title: string | undefined,
    language: string | undefined,
    url: string,
    type: string,
    internal: boolean,
  ) {
    this.title = title
    this.language = language
    this.url = url
    this.type = type
    this.internal = internal
  }

}
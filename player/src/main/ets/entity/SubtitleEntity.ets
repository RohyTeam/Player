export enum SubtitleType {

  ASS,
  SRT

}

export interface SubtitleEntity {

  index: number,
  name: string,
  language: string,
  path: string
  type: SubtitleType
  extra: object | undefined

}

@Observed
export class Subtitles extends Array<SubtitleEntity> {
}
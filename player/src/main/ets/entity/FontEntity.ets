import { FileStatus } from './VideoEntity'

export interface FontEntity {

  familyName: string
  hash: string
  uri: string
  on: boolean

}

export class FontEntityV2 {
  familyName: string
  hash: string
  uri: string
  on: boolean
  status: FileStatus = FileStatus.None

  constructor(
    familyName: string,
    hash: string,
    uri: string,
    on: boolean
  ) {
    this.familyName = familyName
    this.hash = hash
    this.uri = uri
    this.on = on
  }

  public static fromV1(entity: FontEntity): FontEntityV2 {
    return new FontEntityV2(
      entity.familyName,
      entity.hash,
      entity.uri,
      entity.on
    )
  }
}

export class Fonts extends Array<FontEntityV2> {
}
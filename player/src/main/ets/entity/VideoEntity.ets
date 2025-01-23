
export interface VideoEntity {

  uri: string,
  title: string,
  hash: string,
  addedTime: number

}

interface VideoMetadata {

}

export enum FileStatus {

  Authorized,
  Disappear,
  None

}

@Observed
export class VideoEntityV2Array extends Array<VideoEntityV2> {}

@Observed
export class VideoEntityV2 {

  uri: string
  title: string
  hash: string
  addedTime: number
  status: FileStatus = FileStatus.None

  constructor(
    uri: string,
    title: string,
    hash: string,
    addedTime: number
  ) {
    this.uri = uri
    this.title = title
    this.hash = hash
    this.addedTime = addedTime
  }

  public static fromV1(entity: VideoEntity): VideoEntityV2 {
    return new VideoEntityV2(
      entity.uri,
      entity.title,
      entity.hash,
      entity.addedTime
    )
  }

}
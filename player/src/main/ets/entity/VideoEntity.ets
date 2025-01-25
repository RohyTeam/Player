export interface VideoEntity {

  uri: string,
  title: string,
  hash: string,
  addedTime: number,
  fileSource: string

}

interface VideoMetadata {}

export enum FileStatus {

  Authorized,
  Disappear,
  None

}

export class FileSources {
  public static readonly LOCAL_FILE = "local_file"
  public static readonly PHOTOS = "photos"
}

@Observed
export class VideoEntityV2Array extends Array<VideoEntityV2> {
}

@Observed
export class VideoEntityV2 {
  uri: string
  title: string
  hash: string
  addedTime: number
  fileSource: string
  status: FileStatus = FileStatus.None

  constructor(
    uri: string,
    title: string,
    hash: string,
    addedTime: number,
    fileSource: string
  ) {
    this.uri = uri
    this.title = title
    this.hash = hash
    this.addedTime = addedTime
    this.fileSource = fileSource
  }

  public static fromV1(entity: VideoEntity): VideoEntityV2 {
    return new VideoEntityV2(
      entity.uri,
      entity.title,
      entity.hash,
      entity.addedTime,
      entity.fileSource
    )
  }
}
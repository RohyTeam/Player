export interface VideoEntity {

  uri: string,
  title: string,
  hash: string,
  addedTime: number,
  fileSource: string
  length: number
  width: number
  height: number
  cover: ArrayBuffer

}

interface VideoMetadata {}

export enum FileStatus {

  Authorized,
  Importing,
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
  length: number
  width: number
  height: number
  cover: ArrayBuffer
  status: FileStatus = FileStatus.None

  constructor(
    uri: string,
    title: string,
    hash: string,
    addedTime: number,
    fileSource: string,
    length: number,
    width: number,
    height: number,
    cover: ArrayBuffer
  ) {
    this.uri = uri
    this.title = title
    this.hash = hash
    this.addedTime = addedTime
    this.fileSource = fileSource
    this.length = length
    this.width = width
    this.height = height
    this.cover = cover
  }

  public static fromV1(entity: VideoEntity): VideoEntityV2 {
    return new VideoEntityV2(
      entity.uri,
      entity.title,
      entity.hash,
      entity.addedTime,
      entity.fileSource,
      entity.length,
      entity.width,
      entity.height,
      entity.cover
    )
  }
}
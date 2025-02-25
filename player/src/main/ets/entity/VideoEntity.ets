export interface VideoEntity {

  uri: string,
  title: string,
  hash: string,
  addedTime: number,
  fileSource: string
  played: number
  length: number
  width: number
  height: number
  cover: ArrayBuffer

}

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
  played: number
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
    played: number,
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
    this.played = played
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
      entity.played,
      entity.length,
      entity.width,
      entity.height,
      entity.cover
    )
  }
}

export enum SourceType {

  LOCAL,
  PHOTOS,
  WEBDAV

}

@Observed
export class VideoSource {
  uri: string
  title: string
  type: SourceType
  addedTime: number
  played: number
  length: number
  width: number
  height: number
  cover: ArrayBuffer
  status: FileStatus = FileStatus.None

  constructor(
    uri: string,
    title: string,
    type: SourceType,
    addedTime: number,
    played: number,
    length: number,
    width: number,
    height: number,
    cover: ArrayBuffer
  ) {
    this.uri = uri
    this.title = title
    this.type = type
    this.addedTime = addedTime
    this.played = played
    this.length = length
    this.width = width
    this.height = height
    this.cover = cover
  }
}

@Observed
export class LocalVideoSource extends VideoSource {
  hash: string

  constructor(
    uri: string,
    title: string,
    addedTime: number,
    played: number,
    length: number,
    width: number,
    height: number,
    cover: ArrayBuffer,
    hash: string
  ) {
    super(
      uri,
      title,
      SourceType.LOCAL,
      addedTime,
      played,
      length,
      width,
      height,
      cover
    )
    this.hash = hash
  }
}

@Observed
export class PhotosVideoSource extends VideoSource {
  hash: string

  constructor(
    uri: string,
    title: string,
    addedTime: number,
    played: number,
    length: number,
    width: number,
    height: number,
    cover: ArrayBuffer,
    hash: string
  ) {
    super(
      uri,
      title,
      SourceType.LOCAL,
      addedTime,
      played,
      length,
      width,
      height,
      cover
    )
    this.hash = hash
  }
}

export class WebDAVVideoSource extends VideoSource {
  serverUrl: string

  constructor(
    uri: string,
    title: string,
    addedTime: number,
    played: number,
    length: number,
    width: number,
    height: number,
    cover: ArrayBuffer,
    serverUrl: string
  ) {
    super(
      uri,
      title,
      SourceType.LOCAL,
      addedTime,
      played,
      length,
      width,
      height,
      cover
    )
    this.serverUrl = serverUrl
  }
}

@Observed
export class VideosV2 extends Array<VideoSource> {
}
import { Base64Util, StrUtil } from '@pura/harmony-utils'

export enum FileStatus {

  Authorized,
  Importing,
  Disappear,
  NetworkNotAccessible,
  None

}

export enum VideoSourceType {

  LOCAL,
  PHOTOS,
  WEBDAV

}

@Observed
export abstract class VideoSource {
  uri: string
  title: string
  type: VideoSourceType
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
    type: VideoSourceType,
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

  public abstract identity(): string
}

export abstract class LocalVideoSource extends VideoSource {
  hash: string
  private identityCache: string | undefined = undefined

  constructor(
    uri: string,
    title: string,
    type: VideoSourceType,
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
      type,
      addedTime,
      played,
      length,
      width,
      height,
      cover
    )
    this.hash = hash
  }

  public identity(): string {
    if (this.identityCache == undefined) {
      this.identityCache = Base64Util.encodeToStrSync(StrUtil.strToUint8Array(`${this.uri}|${this.hash}`))
    }
    return this.identityCache
  }
}

@Observed
export class FileVideoSource extends LocalVideoSource {
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
      VideoSourceType.LOCAL,
      addedTime,
      played,
      length,
      width,
      height,
      cover,
      hash
    )
  }
}

@Observed
export class PhotosVideoSource extends LocalVideoSource {
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
      VideoSourceType.PHOTOS,
      addedTime,
      played,
      length,
      width,
      height,
      cover,
      hash
    )
  }
}

export class WebDAVVideoSource extends VideoSource {
  serverUrl: string
  private identityCache: string | undefined = undefined

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
      VideoSourceType.WEBDAV,
      addedTime,
      played,
      length,
      width,
      height,
      cover
    )
    this.serverUrl = serverUrl
  }

  public identity(): string {
    if (this.identityCache == undefined) {
      this.identityCache = Base64Util.encodeToStrSync(StrUtil.strToUint8Array(`${this.serverUrl}|${this.uri}`))
    }
    return this.identityCache
  }
}

@Observed
export class Videos extends Array<VideoSource> {
}
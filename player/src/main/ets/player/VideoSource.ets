import { VideoMetadata } from "../metadata/VideoMetadata"
import { hash } from "@kit.CoreFileKit"
import { stringToBytes } from "../utils/StringUtils"

export interface VideoSource {

  identity(): string
  metadata(): VideoMetadata
  type(): VideoSourceType
  url(): string
  headers(): Map<string, string> | undefined
  isNetwork(): boolean
  prepare(): void

}

export class LocalFileVideoSource implements VideoSource {

  private videoMetadata: VideoMetadata
  private fileUrl: string

  constructor(videoMetadata: VideoMetadata, fileUrl: string) {
    this.videoMetadata = videoMetadata
    this.fileUrl = fileUrl
  }

  identity(): string {
    let hasher = hash.createHash("sha256")
    hasher.update(stringToBytes(`files:${this.fileUrl}`).buffer)
    return hasher.digest()
  }

  metadata(): VideoMetadata {
    return this.videoMetadata
  }

  type(): VideoSourceType {
    return VideoSourceType.Files
  }

  url(): string {
    return this.fileUrl
  }

  headers(): Map<string, string> | undefined {
    return undefined
  }

  isNetwork(): boolean {
    return false
  }

  prepare(): void {
  }

}

export enum VideoSourceType {

  Photos,
  Files,
  WebDAV

}
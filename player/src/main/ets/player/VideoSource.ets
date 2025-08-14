import { VideoMetadata } from '../metadata/VideoMetadata'
import { hash } from '@kit.CoreFileKit'
import { stringToBytes } from '../utils/StringUtils'
import { sha256 } from '../utils/HashUtils'
import { SavedVideoMetadata } from '../metadata/SavedVideoMetadata'

export interface VideoSource {

  database(): boolean

  name(): string

  identity(): string

  metadata(): SavedVideoMetadata

  type(): VideoSourceType

  url(): string

  headers(): Record<string, string> | undefined

  isNetwork(): boolean

  prepare(): void

}

export class LocalFileVideoSource implements VideoSource {
  private fromDatabase: boolean
  private videoMetadata: SavedVideoMetadata
  private fileUrl: string
  private videoName: string

  constructor(fromDatabase: boolean, videoMetadata: SavedVideoMetadata, fileUrl: string, videoName: string) {
    this.fromDatabase = fromDatabase
    this.videoMetadata = videoMetadata
    this.fileUrl = fileUrl
    this.videoName = videoName
  }

  database(): boolean {
    return this.fromDatabase
  }

  name(): string {
    return this.videoName
  }

  identity(): string {
    return sha256(`files:${this.fileUrl}`)
  }

  metadata(): SavedVideoMetadata {
    return this.videoMetadata
  }

  type(): VideoSourceType {
    return VideoSourceType.Files
  }

  url(): string {
    return this.fileUrl
  }

  headers(): Record<string, string> | undefined {
    return undefined
  }

  isNetwork(): boolean {
    return false
  }

  prepare(): void {
  }

}

export class PhotosVideoSource implements VideoSource {
  private videoMetadata: SavedVideoMetadata
  private fileUrl: string
  private videoName: string

  constructor(videoMetadata: SavedVideoMetadata, fileUrl: string, videoName: string) {
    this.videoMetadata = videoMetadata
    this.fileUrl = fileUrl
    this.videoName = videoName
  }

  database(): boolean {
    return false
  }

  name(): string {
    return this.videoName
  }

  identity(): string {
    return sha256(`photos:${this.fileUrl}`)
  }

  metadata(): SavedVideoMetadata {
    return this.videoMetadata
  }

  type(): VideoSourceType {
    return VideoSourceType.Photos
  }

  url(): string {
    return this.fileUrl
  }

  headers(): Record<string, string> | undefined {
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
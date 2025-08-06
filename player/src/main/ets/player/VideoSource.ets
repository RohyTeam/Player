export interface VideoSource {

  type(): VideoSourceType
  url(): string
  headers(): Map<string, string> | undefined
  isNetwork(): boolean
  prepare(): void

}

export enum VideoSourceType {

  Photos,
  Files,
  WebDAV

}
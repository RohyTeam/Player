import { collections, lang } from '@kit.ArkTS';

export interface PgsSubtitleImage {
  buffer: ArrayBuffer; // RGBA pixelmap, 使用 ImageUtils#rgbaBufferToPixelMap 来转换成 PixelMap
  width: number;
  height: number;
  x: number; // from top left
  y: number; // from top left
  screenWidth: number
  screenHeight: number
}

export interface SavedPgsSubtitleImage {
  path: string; // image path
  width: number;
  height: number;
  x: number; // from top left
  y: number; // from top left
  screenWidth: number
  screenHeight: number
}

export interface ISendablePgsSubtitleImage extends lang.ISendable {
  buffer: collections.ArrayBuffer; // RGBA pixelmap, 使用 ImageUtils#rgbaBufferToPixelMap 来转换成 PixelMap
  width: number;
  height: number;
  x: number; // from top left
  y: number; // from top left
  screenWidth: number
  screenHeight: number
}

@Sendable
export class SendablePgsSubtitleImage implements ISendablePgsSubtitleImage {
  buffer: collections.ArrayBuffer
  width: number
  height: number
  x: number
  y: number
  screenWidth: number
  screenHeight: number

  constructor(
    buffer: collections.ArrayBuffer,
    width: number,
    height: number,
    x: number,
    y: number,
    screenWidth: number,
    screenHeight: number
  ) {
    this.buffer = new collections.Uint8Array(buffer).buffer
    this.width = width
    this.height = height
    this.x = x
    this.y = y
    this.screenWidth = screenWidth
    this.screenHeight = screenHeight
  }
}
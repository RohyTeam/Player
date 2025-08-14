export interface PgsSubtitleImage {
  buffer: ArrayBuffer; // RGBA pixelmap, 使用 ImageUtils#rgbaBufferToPixelMap 来转换成 PixelMap
  width: number;
  height: number;
  x: number; // from top left
  y: number; // from top left
  screenWidth: number
  screenHeight: number
}
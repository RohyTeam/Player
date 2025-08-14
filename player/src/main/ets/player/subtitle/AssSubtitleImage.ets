export interface AssSubtitleImage {
  buffer: ArrayBuffer; // RGBA pixelmap, 使用 ImageUtils#rgbaBufferToPixelMap 来转换成 PixelMap
  width: number;
  height: number;
  x: number;
  y: number;
}
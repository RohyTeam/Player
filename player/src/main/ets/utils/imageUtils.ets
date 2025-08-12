import image from "@ohos.multimedia.image";

export function rgbaBufferToPixelMap(buffer: ArrayBuffer, width: number, height: number): image.PixelMap | undefined {
  if (buffer.byteLength == 0)
    return undefined
  return image.createPixelMapSync(buffer, {
    srcPixelFormat: image.PixelMapFormat.RGBA_8888,
    pixelFormat: image.PixelMapFormat.RGBA_8888,
    alphaType: image.AlphaType.UNPREMUL,
    size: {
      width: width,
      height: height
    }
  }) // 这个返回值有可能为 undefined，但是他没标
}
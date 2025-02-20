import image from '@ohos.multimedia.image';

export async function pixelMapToArrayBuffer(pixelMap: image.PixelMap): Promise<ArrayBuffer> {
  const imageInfo = await pixelMap.getImageInfo();
  const bufferSize = pixelMap.getPixelBytesNumber();

  const buffer = new ArrayBuffer(bufferSize);
  await pixelMap.readPixelsToBuffer(buffer);

  const headerSize = 12;
  const totalBuffer = new ArrayBuffer(headerSize + buffer.byteLength);
  const dataView = new DataView(totalBuffer);
  dataView.setUint32(0, imageInfo.size.width, true);
  dataView.setUint32(4, imageInfo.size.height, true);
  dataView.setUint32(8, imageInfo.pixelFormat, true);

  new Uint8Array(totalBuffer, headerSize).set(new Uint8Array(buffer));
  return totalBuffer;
}

export async function arrayBufferToPixelMap(buffer: ArrayBuffer): Promise<image.PixelMap> {
  const dataView = new DataView(buffer);
  const width = dataView.getUint32(0, true);
  const height = dataView.getUint32(4, true);
  const pixelFormat = dataView.getUint32(8, true);

  const pixelBytes = buffer.slice(12);

  return await image.createPixelMap(pixelBytes, {
    srcPixelFormat: pixelFormat,
    scaleMode: image.ScaleMode.FIT_TARGET_SIZE,
    size: {
      width: width,
      height: height
    }
  });
}
import { VideoMetadata } from './VideoMetadata';
import { fileIo } from '@kit.CoreFileKit';
import RohyMetadata from 'librohy_metadata.so';
import { media } from '@kit.MediaKit';
import { JSON } from '@kit.ArkTS';

export class MetadataFetcher {
  public static async fetch(path: string, isMedia: boolean, headers?: Record<string, string>): Promise<VideoMetadata> {
    let tempMetadata = RohyMetadata.RohyMetedata_getMetadata(path, headers)
    if (!tempMetadata) {
      throw Error("metadata is undefined")
    }
    let metadata = tempMetadata as VideoMetadata
    if (isMedia) {
      // 对于图库中的文件，需要再用一下系统自带的 AVMetadataExtractor 来解决视频方向的问题
      let file = fileIo.openSync(path)
      let avMetadataExtractor = await media.createAVMetadataExtractor()
      avMetadataExtractor.fdSrc = {
        fd: file.fd
      }
      let avMetadata = await avMetadataExtractor.fetchMetadata()
      let width = parseInt(avMetadata.videoWidth ?? "-1")
      let height = parseInt(avMetadata.videoHeight ?? "-1")
      if (!width || width <= 0) {
        width = metadata.width
      }
      if (!height || height <= 0) {
        height = metadata.height
      }
      if (Math.abs(parseInt(avMetadata.videoOrientation || "0") || 0) == 90) {
        let temp = width
        width = height
        height = temp
      }
      await avMetadataExtractor.release()
      await fileIo.close(file)
      metadata.width = width
      metadata.height = height
    }
    return metadata
  }
  public static async fetchNullable(path: string, isMedia: boolean, headers?: Record<string, string>): Promise<VideoMetadata | undefined> {
    let tempMetadata = RohyMetadata.RohyMetedata_getMetadata(path, headers)
    if (!tempMetadata) {
      return undefined
    }
    let metadata = tempMetadata as VideoMetadata
    if (isMedia) {
      // 对于图库中的文件，需要再用一下系统自带的 AVMetadataExtractor 来解决视频方向的问题
      let file = fileIo.openSync(path)
      let avMetadataExtractor = await media.createAVMetadataExtractor()
      avMetadataExtractor.fdSrc = {
        fd: file.fd
      }
      let avMetadata = await avMetadataExtractor.fetchMetadata()
      let width = parseInt(avMetadata.videoWidth ?? "-1")
      let height = parseInt(avMetadata.videoHeight ?? "-1")
      if (!width || width <= 0) {
        width = metadata.width
      }
      if (!height || height <= 0) {
        height = metadata.height
      }
      if (Math.abs(parseInt(avMetadata.videoOrientation || "0") || 0) == 90) {
        let temp = width
        width = height
        height = temp
      }
      await avMetadataExtractor.release()
      await fileIo.close(file)
      metadata.width = width
      metadata.height = height
    }
    return metadata
  }
}
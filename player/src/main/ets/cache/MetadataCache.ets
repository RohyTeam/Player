import { VideoMetadata } from '../metadata/VideoMetadata';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import RohyMetadata from 'librohy_metadata.so';
import { media } from '@kit.MediaKit';

export class MetadataCache {
  private static cache: Map<string, VideoMetadata> = new Map()

  public static exists(uriOrPath: string): boolean {
    return MetadataCache.cache.has(new fileUri.FileUri(uriOrPath).path)
  }

  public static get(uriOrPath: string): VideoMetadata {
    return MetadataCache.cache.get(new fileUri.FileUri(uriOrPath).path)!
  }

  public static async getOrCreate(uriOrPath: string): Promise<VideoMetadata> {
    let metadata = MetadataCache.cache.get(new fileUri.FileUri(uriOrPath).path)
    if (metadata === undefined) {
      let uri = new fileUri.FileUri(uriOrPath).path
      let tempMetadata = RohyMetadata.RohyMetedata_getMetadata(uri)
      if (!tempMetadata) {
        throw Error("metadata is undefined")
      }
      metadata = tempMetadata as VideoMetadata
      if (uri.startsWith("file://media")) {
        let file = fileIo.openSync(uri)
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
      MetadataCache.put(uriOrPath, metadata)
    }
    return metadata
  }

  public static put(uriOrPath: string, metadata: VideoMetadata) {
    MetadataCache.cache.set(new fileUri.FileUri(uriOrPath).path, metadata)
  }
}
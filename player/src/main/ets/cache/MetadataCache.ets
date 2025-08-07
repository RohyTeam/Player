import { VideoMetadata } from "../metadata/VideoMetadata";
import { fileUri } from "@kit.CoreFileKit";
import RohyMetadata from "librohy_metadata.so"

export class MetadataCache {
  
  private static cache: Map<string, VideoMetadata> = new Map()
  
  public static exists(uriOrPath: string): boolean {
    return MetadataCache.cache.has(new fileUri.FileUri(uriOrPath).path)
  }
  
  public static get(uriOrPath: string): VideoMetadata {
    return MetadataCache.cache.get(new fileUri.FileUri(uriOrPath).path)!
  }
  
  public static getOrCreate(uriOrPath: string): VideoMetadata {
    let metadata = MetadataCache.cache.get(new fileUri.FileUri(uriOrPath).path)
    if (!metadata) {
      let uri = new fileUri.FileUri(uriOrPath).path
      let newMetadata = RohyMetadata.RohyMetedata_getMetadata(uri)
      if (!newMetadata) {
        throw Error("metadata is undefined")
      }
      MetadataCache.put(uriOrPath, newMetadata as VideoMetadata)
      metadata = newMetadata as VideoMetadata
    }
    return metadata
  }
  
  public static put(uriOrPath: string, metadata: VideoMetadata) {
    MetadataCache.cache.set(new fileUri.FileUri(uriOrPath).path, metadata)
  }
  
}
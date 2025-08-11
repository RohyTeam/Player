import { VideoMetadata } from './VideoMetadata';

export class MetadataExtractor {
  private static extract0(url: string, headers?: Map<string, string>): VideoMetadata | undefined {
    return undefined;
  }
}

interface InternalMetadataExtractor {

  extract(url: string, headers?: Map<string, string>): VideoMetadata

}

/*

class InternalMetadataExtractorImpl implements InternalMetadataExtractor {

  async extract(url: string, headers?: Map<string, string>): VideoMetadata {
    if (url.startsWith("file://media")) {
      let file = fileIo.openSync(url)
      let avMetadataExtractor = await media.createAVMetadataExtractor()
      avMetadataExtractor.fdSrc = {
        fd: file.fd
      }
      let metadata = await avMetadataExtractor.fetchMetadata()
      let albumCover = await avMetadataExtractor.fetchAlbumCover()

      return {
        duration: parseInt(metadata.duration ?? "1"),
        bitrate: -1,
        width: parseInt(metadata.videoWidth ?? "1"),
        height: parseInt(metadata.videoHeight ?? "1"),
        hdr: metadata.hdrType != undefined && metadata.hdrType == media.HdrType.AV_HDR_TYPE_VIVID,
        codec: "unknown",
        codecLong: "unknown",
        cover: undefined,
        chapters: [],
        tracks: []
      }
    } else if (url.startsWith("http://") || url.startsWith("https://") || url.startsWith("file://")) {
      let metadata = RohyMetadata.RohyMetedata_getMetadata(url)
      if (!metadata) {
        throw Error("cannot fetch video metadata from provided url")
      }
      return metadata as VideoMetadata
    } else {
      throw Error("unsupported video source url")
    }
  }

}*/

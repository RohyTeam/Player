import { copyVideoMetadata, VideoMetadata } from "../metadata/VideoMetadata";
import { superContext } from "../utils/AbilityUtils";
import { deleteInFiles, existsInFiles, openOrCreateFileInFiles,
  readBufferInFiles,
  readTextInFiles } from "../utils/FileUtils";
import { fileIo } from "@kit.CoreFileKit";
import { JSON } from "@kit.ArkTS";

export class VideoMetadataManager {

  public static save(identity: string, metadata: VideoMetadata) {
    let newMetadata = copyVideoMetadata(metadata)
    newMetadata.cover = undefined // 封面单独保存
    let metadataFile = openOrCreateFileInFiles(`metadatas/${identity}`)
    fileIo.writeSync(metadataFile.fd, JSON.stringify(newMetadata))
    fileIo.closeSync(metadataFile)

    if (metadata.cover) {
      let coverFile = openOrCreateFileInFiles(`covers/${identity}`)
      fileIo.writeSync(coverFile.fd, metadata.cover)
      fileIo.closeSync(coverFile)
    }
  }

  public static load(identity: string): VideoMetadata | undefined {
    if (!existsInFiles(`metadatas/${identity}`)) {
      if (existsInFiles(`covers/${identity}`)) {
        deleteInFiles(`covers/${identity}`)
      }
      return undefined
    }
    let metadata = JSON.parse(readTextInFiles(`metadatas/${identity}`)) as VideoMetadata
    if (existsInFiles(`covers/${identity}`)) {
      metadata.cover = readBufferInFiles(`covers/${identity}`)
    }
    return metadata
  }

}
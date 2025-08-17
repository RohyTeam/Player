import { copyVideoMetadata, VideoMetadata } from "./VideoMetadata";
import { superContext } from "../utils/AbilityUtils";
import {
  createFileInFiles,
  createFileInTemp,
  deleteInFiles,
  deleteInTemp,
  ensurePath,
  ensureUri,
  existsInFiles,
  existsInTemp,
  folderExistsInFiles,
  folderExistsInTemp,
  getPathInFiles,
  getPathInTemp,
  listFolderInFiles,
  listFolderInTemp,
  mkdirsInFiles,
  mkdirsInTemp,
  openOrCreateFileInFiles,
  openOrCreateFileInTemp,
  readBufferInFiles,
  readTextInFiles } from "../utils/FileUtils";
import { fileIo } from "@kit.CoreFileKit";
import { JSON } from "@kit.ArkTS";
import RohyMetadata from 'librohy_metadata.so';
import { PhotosVideoSource, VideoSource, VideoSourceType } from "../player/VideoSource";
import { Codec, CodecConstants } from "../constants/CodecConstants";
import { SavedVideoMetadata } from "./SavedVideoMetadata";
import { data } from "@kit.TelephonyKit";
import { SubtitleInfo } from "../player/subtitle/SubtitleInfo";

interface ExportInfo {
  index: number
  dest: string
  codec: Codec
  name: string
}

export class VideoMetadataManager {

  public static exists(identity: string): boolean {
    return VideoMetadataManager.existsInFiles(identity) || VideoMetadataManager.existsInTemp(identity)
  }

  public static existsInFiles(identity: string): boolean {
    return folderExistsInFiles(`videos/${identity}`)
  }

  public static existsInTemp(identity: string): boolean {
    return folderExistsInTemp(`videos/${identity}`)
  }

  public static tempToFile(identity: string) {
    if (!existsInTemp(identity))
      return
    if (existsInFiles(identity))
      return
    fileIo.copyDirSync(getPathInTemp(`videos/${identity}`), getPathInFiles(`videos/${identity}`), 1)
  }

  public static save(identity: string, database: boolean, url: string, metadata: VideoMetadata, headers?: Record<string, string>): SavedVideoMetadata | undefined { // if file url presented, save tracks
    if (!metadata.cover)
      return undefined
    if (VideoMetadataManager.exists(identity))
      return undefined

    let newMetadata = copyVideoMetadata(metadata)
    newMetadata.cover = undefined // 封面单独保存

    let openOrCreateFile = (path: string): fileIo.File => {
      if (database) {
        return openOrCreateFileInFiles(path)
      } else {
        return openOrCreateFileInTemp(path)
      }
    }

    let mkdirs = (path: string): void => {
      if (database) {
        mkdirsInFiles(path)
      } else {
        mkdirsInTemp(path)
      }
    }

    let getPath = (path: string): string => {
      if (database) {
        return getPathInFiles(path)
      } else {
        return getPathInTemp(path)
      }
    }

    mkdirs(`videos/${identity}`)

    let metadataFile = openOrCreateFile(`videos/${identity}/metadata.json`)
    fileIo.writeSync(metadataFile.fd, JSON.stringify(newMetadata))
    fileIo.closeSync(metadataFile)

    if (metadata.cover) {
      let coverFile = openOrCreateFile(`videos/${identity}/cover.jpg`)
      fileIo.writeSync(coverFile.fd, metadata.cover)
      fileIo.closeSync(coverFile)
    }

    let subtitles: ExportInfo[] = []

    for (let track of metadata.tracks) {
      if (track.type == 2 && track.codec != undefined) {
        let codec = CodecConstants.getCodec(track.codec)
        if (codec == undefined)
          continue
        subtitles.push({
          index: track.index,
          dest: getPath(`videos/${identity}/subtitles/subtitle_${track.index}.${codec.extension}`),
          codec: codec,
          name: `subtitles_${track.index}.${codec.extension}`
        })
      }
    }
    if (subtitles.length > 0) {
      mkdirs(`videos/${identity}/subtitles`)
      RohyMetadata.RohyMetadata_extractTracks(ensurePath(url), subtitles, headers)
    }

    let subtitleInfos: SubtitleInfo[] = []
    subtitles.sort((a, b) => a.name.localeCompare(b.name))
      .forEach((exportInfo, index) => {
        if (exportInfo.codec.id != 'ass' && exportInfo.codec.id != "srt" && exportInfo.codec.id != "pgs")
          return
        subtitleInfos.push({
          title: $r("app.string.internal_subtitle", `#${index + 1}`),
          language: undefined,
          type: exportInfo.codec.id,
          url: exportInfo.dest,
          internal: true
        })
      })
    return {
      metadata: metadata,
      identity: identity,
      subtitles: subtitleInfos
    }
  }

  public static loadAsync(identity: string): Promise<SavedVideoMetadata | undefined> {
    return new Promise((resolver) => {
      return resolver(VideoMetadataManager.load(identity))
    })
  }

  public static load(identity: string): SavedVideoMetadata | undefined {
    if (!VideoMetadataManager.exists(identity))
      return undefined

    let inFiles = VideoMetadataManager.existsInFiles(identity)

    let fileExists = (path: string): boolean => {
      if (inFiles) {
        return existsInFiles(path)
      } else {
        return existsInTemp(path)
      }
    }

    let getPath = (path: string): string => {
      if (inFiles) {
        return getPathInFiles(path)
      } else {
        return getPathInTemp(path)
      }
    }

    let listFolder = (path: string): string[] => {
      if (inFiles) {
        return listFolderInFiles(path)
      } else {
        return listFolderInTemp(path)
      }
    }

    if (!fileExists(`videos/${identity}/metadata.json`)) {
      VideoMetadataManager.delete(identity)
      return undefined
    }

    if (!fileExists(`videos/${identity}/cover.jpg`)) {
      VideoMetadataManager.delete(identity)
      return undefined
    }

    let metadata: VideoMetadata = JSON.parse(fileIo.readTextSync(getPath(`videos/${identity}/metadata.json`))) as VideoMetadata

    metadata.cover = ensureUri(getPath(`videos/${identity}/cover.jpg`))

    let subtitleInfos: SubtitleInfo[] = []

    if (fileExists(`videos/${identity}/subtitles`)) {
      listFolder(`videos/${identity}/subtitles`)
        .sort((a, b) => a.localeCompare(b))
        .forEach((fileName, index) => {
          if (fileName.endsWith(".srt")) {
            subtitleInfos.push({
              title: $r("app.string.internal_subtitle", `#${index + 1}`),
              language: undefined,
              type: 'srt',
              url: getPath(`videos/${identity}/subtitles/${fileName}`),
              internal: true
            })
          } else if (fileName.endsWith(".ass")) {
            subtitleInfos.push({
              title: $r("app.string.internal_subtitle", `#${index + 1}`),
              language: undefined,
              type: 'ass',
              url: getPath(`videos/${identity}/subtitles/${fileName}`),
              internal: true
            })
          } else if (fileName.endsWith(".sup")) {
            subtitleInfos.push({
              title: $r("app.string.internal_subtitle", `#${index + 1}`),
              language: undefined,
              type: 'pgs',
              url: getPath(`videos/${identity}/subtitles/${fileName}`),
              internal: true
            })
          }
        })
    }

    return {
      metadata: metadata,
      identity: identity,
      subtitles: subtitleInfos
    }
  }

  public static delete(identity: string) {
    deleteInFiles(`videos/${identity}`)
    deleteInTemp(`videos/${identity}`)
  }

}
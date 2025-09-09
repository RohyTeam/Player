import { copyVideoMetadata, VideoMetadata } from './VideoMetadata';
import { ensurePath, ensureUri, fileName as getFileName } from '../utils/FileUtils';
import { fileIo } from '@kit.CoreFileKit';
import { JSON } from '@kit.ArkTS';
import RohyMetadata from 'librohy_metadata.so';
import { Codec, CodecConstants } from '../constants/CodecConstants';
import { SavedVideoMetadata } from './SavedVideoMetadata';
import { SubtitleInfo } from '../player/subtitle/SubtitleInfo';
import { appFileSystem, FileSystem } from '../filemanagement/FileSystem';

interface ExportInfo {
  index: number
  dest: string
  codec: Codec
  name: string
}

export class VideoMetadataManager {
  public static exists(identity: string, fs?: FileSystem): boolean {
    return VideoMetadataManager.existsInFiles(identity, fs) || VideoMetadataManager.existsInTemp(identity, fs)
  }

  public static existsInFiles(identity: string, fs?: FileSystem): boolean {
    return (fs ?? appFileSystem()).folderExistsInFiles(`videos/${identity}`)
  }

  public static existsInTemp(identity: string, fs?: FileSystem): boolean {
    return (fs ?? appFileSystem()).folderExistsInTemp(`videos/${identity}`)
  }

  public static tempToFile(identity: string, fileSystem?: FileSystem) {
    let fs = fileSystem ?? appFileSystem()
    if (!fs.existsInTemp(identity)) {
      return
    }
    if (fs.existsInFiles(identity)) {
      return
    }
    fileIo.copyDirSync(fs.getPathInTemp(`videos/${identity}`), fs.getPathInFiles(`videos/${identity}`), 1)
  }

  public static save(identity: string, database: boolean, url: string, metadata: VideoMetadata, fileSystem?: FileSystem,
    headers?: Record<string, string>): SavedVideoMetadata | undefined { // if file url presented, save tracks
    if (!metadata.cover) {
      return undefined
    }
    if (VideoMetadataManager.exists(identity, fileSystem)) {
      return undefined
    }

    let fs = fileSystem ?? appFileSystem()

    let newMetadata = copyVideoMetadata(metadata)
    newMetadata.cover = undefined // 封面单独保存

    let openOrCreateFile = (path: string): fileIo.File => {
      if (database) {
        return fs.openOrCreateFileInFiles(path)
      } else {
        return fs.openOrCreateFileInTemp(path)
      }
    }

    let mkdirs = (path: string): void => {
      if (database) {
        fs.mkdirsInFiles(path)
      } else {
        fs.mkdirsInTemp(path)
      }
    }

    let getPath = (path: string): string => {
      if (database) {
        return fs.getPathInFiles(path)
      } else {
        return fs.getPathInTemp(path)
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
        if (codec == undefined) {
          continue
        }
        subtitles.push({
          index: track.index,
          dest: getPath(`videos/${identity}/subtitles/subtitle_${track.index}.${codec.extension}`),
          codec: codec,
          name: `subtitles_${track.index}.${codec.extension}`
        })
      }
    }
    mkdirs(`videos/${identity}/subtitles`)
    if (subtitles.length > 0) {
      RohyMetadata.RohyMetadata_extractTracks(ensurePath(url), subtitles, headers)
    }

    let subtitleInfos: SubtitleInfo[] = []
    subtitles.sort((a, b) => a.name.localeCompare(b.name))
      .forEach((exportInfo, index) => {
        if (exportInfo.codec.id != 'ass' && exportInfo.codec.id != "srt" && exportInfo.codec.id != "pgs") {
          return
        }
        subtitleInfos.push({
          title: undefined,
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

  public static loadAsync(identity: string, fs?: FileSystem): Promise<SavedVideoMetadata | undefined> {
    return new Promise((resolver) => {
      return resolver(VideoMetadataManager.load(identity, fs))
    })
  }

  public static load(identity: string, fileSystem?: FileSystem): SavedVideoMetadata | undefined {
    if (!VideoMetadataManager.exists(identity, fileSystem)) {
      return undefined
    }

    let inFiles = VideoMetadataManager.existsInFiles(identity, fileSystem)

    let fs = fileSystem ?? appFileSystem()

    let fileExists = (path: string): boolean => {
      if (inFiles) {
        return fs.existsInFiles(path)
      } else {
        return fs.existsInTemp(path)
      }
    }

    let getPath = (path: string): string => {
      if (inFiles) {
        return fs.getPathInFiles(path)
      } else {
        return fs.getPathInTemp(path)
      }
    }

    let listFolder = (path: string): string[] => {
      if (inFiles) {
        return fs.listFolderInFiles(path)
      } else {
        return fs.listFolderInTemp(path)
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

    // 拯救一下邀测用户
    let metadataText = fileIo.readTextSync(getPath(`videos/${identity}/metadata.json`))
      .replace('"hdr":false"', '"hdr":0')
      .replace('"hdr":true"', '"hdr":4')

    let metadata: VideoMetadata = JSON.parse(metadataText) as VideoMetadata

    metadata.cover = ensureUri(getPath(`videos/${identity}/cover.jpg`))

    let subtitleInfos: SubtitleInfo[] = []

    if (fileExists(`videos/${identity}/subtitles`)) {
      listFolder(`videos/${identity}/subtitles`)
        .sort((a, b) => a.localeCompare(b))
        .forEach((fileName, index) => {
          if (fileName.endsWith(".srt")) {
            subtitleInfos.push({
              title: undefined,
              language: undefined,
              type: 'srt',
              url: getPath(`videos/${identity}/subtitles/${fileName}`),
              internal: true
            })
          } else if (fileName.endsWith(".ass")) {
            subtitleInfos.push({
              title: undefined,
              language: undefined,
              type: 'ass',
              url: getPath(`videos/${identity}/subtitles/${fileName}`),
              internal: true
            })
          } else if (fileName.endsWith(".sup") || fileName.endsWith(".rohy_pgs")) {
            subtitleInfos.push({
              title: undefined,
              language: undefined,
              type: 'pgs',
              url: getPath(`videos/${identity}/subtitles/${fileName}`),
              internal: true
            })
          }
        })
    }
    if (fileExists(`videos/${identity}/external_subtitles`)) {
      listFolder(`videos/${identity}/external_subtitles`)
        .sort((a, b) => a.localeCompare(b))
        .forEach((fileName) => {
          if (fileName.endsWith(".srt")) {
            subtitleInfos.push({
              title: getFileName(getPath(`videos/${identity}/external_subtitles/${fileName}`)),
              language: undefined,
              type: 'srt',
              url: getPath(`videos/${identity}/external_subtitles/${fileName}`),
              internal: false
            })
          } else if (fileName.endsWith(".ass")) {
            subtitleInfos.push({
              title: getFileName(getPath(`videos/${identity}/external_subtitles/${fileName}`)),
              language: undefined,
              type: 'ass',
              url: getPath(`videos/${identity}/external_subtitles/${fileName}`),
              internal: false
            })
          } else if (fileName.endsWith(".sup") || fileName.endsWith(".rohy_pgs")) {
            subtitleInfos.push({
              title: getFileName(getPath(`videos/${identity}/external_subtitles/${fileName}`)),
              language: undefined,
              type: 'pgs',
              url: getPath(`videos/${identity}/external_subtitles/${fileName}`),
              internal: false
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

  public static delete(identity: string, fs?: FileSystem) {
    try {
      (fs ?? appFileSystem()).deleteInFiles(`videos/${identity}`, true);
    } catch {
    }
    try {
      (fs ?? appFileSystem()).deleteInTemp(`videos/${identity}`, true)
    } catch {
    }
  }
}
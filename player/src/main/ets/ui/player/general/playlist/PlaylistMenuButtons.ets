import { pickVideoFiles } from '../../../../utils/PickerUtils'
import { CircleIconButton } from '../../../button/CircleIconButton'
import { PlaylistImportSheet } from './sheet/PlaylistImportSheet'
import { ComponentContent } from '@kit.ArkUI'
import { collections, taskpool } from '@kit.ArkTS'
import { sha256 } from '../../../../utils/HashUtils'
import { PlaylistFolderItemsDataSource } from '../../../../datasource/playlist/PlaylistFolderItemsDataSource'
import { ImportProgressContext,
  showEasyImportProgressDialog } from '../../../overlay/ImportProgressOverlay'
import { MetadataFetcher } from '../../../../metadata/MetadataFetcher'
import { ensurePath, fileName } from '../../../../utils/FileUtils'
import { fileIo, fileShare, hash } from '@kit.CoreFileKit'
import { VideoMetadataManager } from '../../../../metadata/VideoMetadataManager'
import {
  createSendableVideoMetadata,
  SendableVideoMetadata,
  sendableVideoMetadataToNormal
} from '../../../../metadata/VideoMetadata'
import { ensureContext } from '../../../../utils/AbilityUtils'
import { asyncSave } from '../../../../metadata/SendableVideoMetadataManager'
import { BusinessError } from '@kit.BasicServicesKit'
import { showEasyImportErrorDialog } from './dialog/ImportErrorDialog'
import { DialogHelper } from '@pura/harmony-dialog'
import RohyMetadata from 'librohy_metadata.so'

export class ImportErrorType {

  public static readonly NOT_IN_FILES: ImportErrorType = new ImportErrorType("not_in_files", $r("app.string.photos_not_importable"))
  public static readonly DUPLICATED: ImportErrorType = new ImportErrorType("duplicated", $r("app.string.video_imported"))
  public static readonly FETCH_METADATA: ImportErrorType = new ImportErrorType("fetch_metadata", $r("app.string.failed_to_fetch_metadata"))
  public static readonly SAVE_METADATA: ImportErrorType = new ImportErrorType("save_metadata", $r("app.string.failed_to_save_metadata"))
  public static readonly STORAGE_FULL: ImportErrorType = new ImportErrorType("storage_full", $r("app.string.storage_is_not_enough"))
  public static readonly PERSIST_FILE: ImportErrorType = new ImportErrorType("persist_file", $r("app.string.faield_to_persist_file"))
  public static readonly ACCESS_FILE: ImportErrorType = new ImportErrorType("access_file", $r("app.string.failed_to_access_file"))
  public static readonly HASH_FILE: ImportErrorType = new ImportErrorType("access_file", $r("app.string.failed_to_access_file"))
  public static readonly UNKNOWN: ImportErrorType = new ImportErrorType("unknown", $r("app.string.unknown_error"))

  public static readonly TYPES: ImportErrorType[] = [
    ImportErrorType.NOT_IN_FILES,
    ImportErrorType.DUPLICATED,
    ImportErrorType.FETCH_METADATA,
    ImportErrorType.SAVE_METADATA,
    ImportErrorType.STORAGE_FULL,
    ImportErrorType.PERSIST_FILE,
    ImportErrorType.ACCESS_FILE,
    ImportErrorType.UNKNOWN
  ]

  readonly id: string
  readonly reason: ResourceStr

  constructor(id: string, reason: ResourceStr) {
    this.id = id
    this.reason = reason
  }

}

export interface ImportError {

  url: string
  reason: ImportErrorType

}

export interface ImportVideo {
  name: string
  identity: string
  url: string
  hash: string
  size: number
}

interface FilterUrl {
  uri: string
  size: number
}

@Concurrent
function hashFile(path: string, size: number): string | undefined {
  return RohyMetadata.RohyMetadata_hashFile(path, size)
}

@Concurrent
async function fetchMetadata(uri: string, path: string, isMedia: boolean, headers: collections.Map<string, string>) {
  let realHeaders: Record<string, string> = {}
  for (let key of headers.keys()) {
    realHeaders[key] = headers.get(key)!
  }
  let metadata = await MetadataFetcher.fetchNullable(path, isMedia, realHeaders)
  if (metadata) {
    taskpool.Task.sendData(
      createSendableVideoMetadata(metadata)
    )
  } else {
    taskpool.Task.sendData(2)
  }
}

@ComponentV2
export struct PlaylistMenuButtons {
  @Consumer("playlistFolderDataSource")
  playlistFolderDataSource?: PlaylistFolderItemsDataSource
  @Local
  private showImportVideoSheet: boolean = false
  @Local
  importProgressContext: ImportProgressContext = ImportProgressContext.reach(this.getUIContext())

  build() {
    Row() {
      CircleIconButton({
        icon: $r("sys.symbol.plus"),
        buttonMargin: {
          right: 8
        },
        clickCallback: () => {
          // this.showImportVideoSheet = true
          if (!this.playlistFolderDataSource) {
            return
          }

          pickVideoFiles(this.getUIContext(), 500)
            .then(async (urls) => {
              if (urls.length == 0) {
                return
              }

              let tasks: Record<string, taskpool.Task> = {}
              let importErrors: ImportError[] = []
              let importVideos: ImportVideo[] = []

              this.importProgressContext.current = 0
              this.importProgressContext.total = urls.length
              this.importProgressContext.subProgressCurrent = 0
              this.importProgressContext.subProgressTotal = urls.length * 6

              let cancelled = false
              let finished = false

              let startedTask: taskpool.Task[] = []

              let importProgressDialogId = showEasyImportProgressDialog(() => {
                cancelled = true
                for (let task of Object.values(tasks)) {
                  if (!task.isDone() && startedTask.indexOf(task) < 0) {
                    try {
                      taskpool.cancel(task)
                    } catch (_) {
                    }
                  }
                }
              })

              let filteredUrls: FilterUrl[] = []
              for (let uri of urls) {
                this.importProgressContext.subProgressCurrent += 1
                this.importProgressContext.subProgressText = $r("app.string.import_verify_file", fileName(uri))
                let identity = sha256(`files:${uri}`)
                if (this.playlistFolderDataSource!.hasVideo(identity)) {
                  importErrors.push({
                    url: uri,
                    reason:ImportErrorType.DUPLICATED
                  })
                  this.importProgressContext.subProgressCurrent += 5
                  this.importProgressContext.current += 1
                  continue
                }
                try {
                  let file = fileIo.openSync(uri)
                  let stat = fileIo.statSync(file.fd)
                  let location = stat.location
                  let size = stat.size
                  fileIo.closeSync(file)
                  if (location == 1) {
                    filteredUrls.push({
                      uri: uri,
                      size: size
                    })
                  } else {
                    importErrors.push({
                      url: uri,
                      reason: ImportErrorType.NOT_IN_FILES
                    })
                    this.importProgressContext.subProgressCurrent += 5
                    this.importProgressContext.current += 1
                    continue
                  }
                } catch (_) {
                  importErrors.push({
                    url: uri,
                    reason: ImportErrorType.ACCESS_FILE
                  })
                  this.importProgressContext.subProgressCurrent += 5
                  this.importProgressContext.current += 1
                  continue
                }
              }

              if (filteredUrls.length <= 0) {
                setTimeout(() => {
                  DialogHelper.closeDialog(importProgressDialogId)
                }, 10)
                if (importErrors.length > 0) {
                  showEasyImportErrorDialog(importErrors)
                }
                return
              }

              let plusOne = () => {
                this.importProgressContext.current += 1
                if (this.importProgressContext.current >= this.importProgressContext.total) {
                  DialogHelper.closeDialog(importProgressDialogId)
                  if (!cancelled && !finished) {
                    finished = true
                    for (let video of importVideos) {
                      this.playlistFolderDataSource?.importVideo(video.name, video.identity, video.url, video.hash, video.size)
                    }
                    if (importErrors.length > 0) {
                      showEasyImportErrorDialog(importErrors)
                    }
                  }
                }
              }

              for (let filteredUri of filteredUrls) {
                let uri = filteredUri.uri
                let identity = sha256(`files:${uri}`)
                let task = new taskpool.Task(fetchMetadata, uri, ensurePath(uri), true, new collections.Map<string, string>())
                task.onReceiveData(async (result: SendableVideoMetadata | number) => {
                  if (typeof result == 'number') {
                    importErrors.push({
                      url: uri,
                      reason: ImportErrorType.TYPES[result]
                    })
                    plusOne()
                    return
                  }
                  let metadata = sendableVideoMetadataToNormal(result)
                  this.importProgressContext.subProgressCurrent += 1
                  this.importProgressContext.subProgressText = $r("app.string.import_persisting", fileName(uri))

                  let persist = (hash: string) => {
                    fileShare.persistPermission([{
                      uri: uri,
                      operationMode: fileShare.OperationMode.READ_MODE
                    }])
                      .then(() => {
                        let continueJob: () => void = () => {
                          importVideos.push({
                            name: fileName(uri),
                            identity: identity,
                            url: uri,
                            hash: hash,
                            size: filteredUri.size
                          })
                          this.importProgressContext.subProgressCurrent += 1
                          this.importProgressContext.subProgressText = $r("app.string.import_finished", fileName(uri))
                        }
                        this.importProgressContext.subProgressCurrent += 1
                        this.importProgressContext.subProgressText = $r("app.string.import_saving", fileName(uri))
                        if (!VideoMetadataManager.existsInFiles(identity)) {
                          if (VideoMetadataManager.existsInTemp(identity)) {
                            VideoMetadataManager.tempToFile(identity)
                            continueJob()
                          } else {
                            asyncSave(
                              ensureContext(this.getUIContext()).tempDir,
                              ensureContext(this.getUIContext()).filesDir,
                              identity,
                              true,
                              uri,
                              createSendableVideoMetadata(metadata)
                            )
                              .then(() => {
                                continueJob()
                                plusOne()
                              })
                              .catch(() => {
                                importErrors.push({
                                  url: uri,
                                  reason: ImportErrorType.SAVE_METADATA
                                })
                                plusOne()
                              })
                          }
                        } else {
                          continueJob()
                          plusOne()
                        }
                      })
                      .catch(() => {
                        this.importProgressContext.subProgressCurrent += 1
                        importErrors.push({
                          url: uri,
                          reason: ImportErrorType.SAVE_METADATA
                        })
                        plusOne()
                      })
                  }

                  let failHash = () => {
                    this.importProgressContext.subProgressCurrent += 2
                    importErrors.push({
                      url: uri,
                      reason: ImportErrorType.HASH_FILE
                    })
                    plusOne()
                  }

                  taskpool.execute(hashFile, ensurePath(uri), filteredUri.size)
                    .then((result) => {
                      if (result === undefined || typeof result !== 'string') {
                        failHash()
                      } else {
                        console.error(`file hash is: ${result}`)
                        persist(result)
                      }
                    })
                    .catch(() => {
                      failHash()
                    })
                })
                task.onExecutionFailed((err) => {
                  this.importProgressContext.current += 1
                  this.importProgressContext.subProgressCurrent += 3
                  importErrors.push({
                    url: uri,
                    reason: ImportErrorType.UNKNOWN
                  })
                  plusOne()
                })
                tasks[uri] = task
              }

              for (let entry of Object.entries(tasks)) {
                if (cancelled)
                  break
                let uri = entry[0]
                let task = entry[1]
                this.importProgressContext.subProgressCurrent += 1
                this.importProgressContext.subProgressText = $r("app.string.import_fetching_metadata", fileName(uri))
                taskpool.execute(task)
                  .then(() => {})
                  .catch(() => {
                    importErrors.push({
                      url: uri,
                      reason: ImportErrorType.FETCH_METADATA
                    })
                    plusOne()
                  })
                startedTask.push(task)
              }
            })
        }
      })
        .bindSheet(
          this.showImportVideoSheet!!,
          this.ImportVideoSheet,
          {
            backgroundColor: $r("app.color.rohy_background"),
            height: SheetSize.FIT_CONTENT,
            dragBar: false,
            shadow: ShadowStyle.OUTER_DEFAULT_MD,
            showClose: true,
            preferType: SheetType.CENTER,
            enableOutsideInteractive: false,
            mode: SheetMode.OVERLAY,
            onWillDismiss: () => {
              this.showImportVideoSheet = false
            },
            title: {
              title: $r("app.string.import_video"),
              subtitle: $r("app.string.not_implemented")
            }
          }
        )
    }
    .margin({
      right: 8,
      top: 8
    })
  }

  @Builder
  private ImportVideoSheet() {
    PlaylistImportSheet({
      hideChooser: () => {
        this.showImportVideoSheet = false
      }
    })
  }
}
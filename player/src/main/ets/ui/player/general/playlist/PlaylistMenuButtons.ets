import { pickVideoFiles } from '../../../../utils/PickerUtils'
import { CircleIconButton } from '../../../button/CircleIconButton'
import { PlaylistImportSheet } from './sheet/PlaylistImportSheet'
import { ComponentContent } from '@kit.ArkUI'
import { collections, taskpool } from '@kit.ArkTS'
import { sha256 } from '../../../../utils/HashUtils'
import { PlaylistFolderItemsDataSource } from '../../../../datasource/playlist/PlaylistFolderItemsDataSource'
import { ImportProgressContext, ImportProgressOverlayBuilder } from '../../../overlay/ImportProgressOverlay'
import { MetadataFetcher } from '../../../../metadata/MetadataFetcher'
import { ensurePath, fileName } from '../../../../utils/FileUtils'
import { fileShare } from '@kit.CoreFileKit'
import { VideoMetadataManager } from '../../../../metadata/VideoMetadataManager'
import {
  createSendableVideoMetadata,
  SendableVideoMetadata,
  sendableVideoMetadataToNormal
} from '../../../../metadata/VideoMetadata'
import { ensureContext } from '../../../../utils/AbilityUtils'
import { asyncSave } from '../../../../metadata/SendableVideoMetadataManager'
import { BusinessError } from '@kit.BasicServicesKit'

interface ImportError {

  url: string
  reason: ResourceStr

}

@Concurrent
async function fetchMetadata(path: string, isMedia: boolean, headers: collections.Map<string, string>) {
  let realHeaders: Record<string, string> = {}
  for (let key of headers.keys()) {
    realHeaders[key] = headers.get(key)!
  }
  let metadata = await MetadataFetcher.fetch(path, isMedia, realHeaders)
  taskpool.Task.sendData(
    createSendableVideoMetadata(metadata)
  )
}

@ComponentV2
export struct PlaylistMenuButtons {
  @Consumer("playlistFolderDataSource")
  playlistFolderDataSource?: PlaylistFolderItemsDataSource
  @Local
  private showImportVideoSheet: boolean = false
  @Local
  importProgressContext: ImportProgressContext = new ImportProgressContext()

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
              let importErrors: ImportError[] = []

              let filteredUrls: string[] = []
              for (let uri of urls) {
                if (!uri.startsWith("file://docs")) {
                  importErrors.push({
                    url: uri,
                    reason: $r('app.string.photos_not_importable')
                  })
                  continue
                }
                let identity = sha256(`files:${uri}`)
                if (this.playlistFolderDataSource!.hasVideo(identity)) {
                  importErrors.push({
                    url: uri,
                    reason: $r('app.string.video_imported')
                  })
                  continue
                }

                filteredUrls.push(uri)
              }

              this.importProgressContext.current = 0
              this.importProgressContext.total = filteredUrls.length

              let importProgressOverlayComponent: ComponentContent<ImportProgressContext> = new ComponentContent(
                this.getUIContext(),
                wrapBuilder(ImportProgressOverlayBuilder),
                this.importProgressContext
              )

              this.getUIContext().getPromptAction().openCustomDialog(
                importProgressOverlayComponent,
                {
                  autoCancel: false,
                  onWillDismiss: () => {
                  }
                }
              )

              let taskGroup = new taskpool.TaskGroup()
              for (let uri of filteredUrls) {
                let identity = sha256(`files:${uri}`)
                let task =
                  new taskpool.Task(fetchMetadata, ensurePath(uri), true, new collections.Map<string, string>())
                task.onReceiveData(async (result: SendableVideoMetadata) => {
                  if (!result) {
                    return
                  }
                  let metadata = sendableVideoMetadataToNormal(result)
                  await fileShare.persistPermission([{
                    uri: uri,
                    operationMode: fileShare.OperationMode.READ_MODE
                  }])
                  let continueJob: () => void = () => {
                    this.playlistFolderDataSource?.importVideo(fileName(uri), identity, uri)
                    this.importProgressContext.current += 1
                    if (this.importProgressContext.current >= this.importProgressContext.total) {
                      this.getUIContext().getPromptAction().closeCustomDialog(importProgressOverlayComponent)
                      importProgressOverlayComponent.dispose()
                      // TODO: 显示所有的错误和问题
                    }
                  }
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
                        })
                        .catch((err: BusinessError) => {
                          console.error(`error occurs fucking: ${err.message} (${err.code})`)
                        })
                    }
                  } else {
                    continueJob()
                  }

                })
                task.onExecutionFailed((err) => {
                  this.importProgressContext.current += 1
                  importErrors.push({
                    url: uri,
                    reason: err.message
                  })
                  if (this.importProgressContext.current >= this.importProgressContext.total) {
                    this.getUIContext().getPromptAction().closeCustomDialog(importProgressOverlayComponent)
                    importProgressOverlayComponent.dispose()
                    // TODO: 显示所有的错误和问题
                  }
                })
                taskGroup.addTask(task)
              }

              taskpool.execute(taskGroup)
            })

          /*pickSingleVideoFile(this.getUIContext())
            .then(async (url) => {
              if (!url)
                return
              if (!url.startsWith("file://docs")) {
                promptAction.showToast({
                  message: $r('app.string.photos_not_importable')
                })
                return
              }
              let identity = sha256(`files:${url}`)
              if (this.playlistFolderDataSource!.hasVideo(identity)) {
                // TODO: 未来要将重复导入的视频作为错误添加到一个列表中，等所有任务执行完以后给用户展示
                promptAction.showToast({
                  message: $r('app.string.video_imported')
                })
                return
              }
              this.importProgressContext.current = 0
              this.importProgressContext.total = 1

              let importProgressOverlayComponent: ComponentContent<ImportProgressContext> = new ComponentContent(
                this.getUIContext(),
                wrapBuilder(ImportProgressOverlayBuilder),
                this.importProgressContext
              )

              this.getUIContext().getPromptAction().openCustomDialog(
                importProgressOverlayComponent,
                {
                  autoCancel: false,
                  onWillDismiss: () => {
                  }
                }
              )

              for (let uri of [url]) {
                let identity = sha256(`files:${uri}`)
                let metadata = await MetadataFetcher.fetch(ensurePath(uri), false)
                await fileShare.persistPermission([{
                  uri: uri,
                  operationMode: fileShare.OperationMode.READ_MODE
                }])
                VideoMetadataManager.save(identity, true, url, metadata)
                this.playlistFolderDataSource?.importVideo(fileName(uri), identity, uri)
                this.importProgressContext.current += 1
                if (this.importProgressContext.current >= this.importProgressContext.total) {
                  this.getUIContext().getPromptAction().closeCustomDialog(importProgressOverlayComponent)
                  importProgressOverlayComponent.dispose()
                }
              }

              */
          /*
                                        let closed: boolean = false

                                        let taskGroup = new taskpool.TaskGroup()

                                        // TODO: 未来替换成可以选择大量文件，然后遍历所有的 url
                                        for (let uri of [url]) {
                                          let identity = sha256(`files:${uri}`)
                                          let task = new taskpool.Task(importVideo, [ensurePath(uri)])
                                          task.onReceiveData(async (metadata: VideoMetadata) => {
                                            await fileShare.persistPermission([{
                                              uri: uri,
                                              operationMode: fileShare.OperationMode.READ_MODE
                                            }])
                                            console.error(`FUCK: persisted`)
                                            VideoMetadataManager.save(identity, true, url, metadata)
                                            console.error(`FUCK: saved`)
                                            this.playlistFolderDataSource?.importVideo(fileName(uri), identity, uri)
                                          })
                                          task.onExecutionSucceeded(() => {
                                            console.error(`FUCK: sucess importing`)
                                            this.importProgressContext.current += 1
                                            if (this.importProgressContext.current >= this.importProgressContext.total && !closed) {
                                              closed = true
                                              this.getUIContext().getPromptAction().closeCustomDialog(importProgressOverlayComponent)
                                              importProgressOverlayComponent.dispose()
                                            }
                                          })
                                          // TODO: 未来要将所有的错误都添加到一个列表中，等所有任务执行完以后给用户展示
                                          task.onExecutionFailed((e: Error) => {
                                            this.importProgressContext.current += 1
                                            if (this.importProgressContext.current >= this.importProgressContext.total && !closed) {
                                              closed = true
                                              this.getUIContext().getPromptAction().closeCustomDialog(importProgressOverlayComponent)
                                              importProgressOverlayComponent.dispose()
                                            }
                                            console.error(`FUCK: error when importing: ${e.message}`)
                                          })
                                          taskGroup.addTask(task)
                                        }

                                        taskpool.execute(taskGroup)
                                          .then(() => {
                                            console.error(`finished all tasks, removing dialog`)
                                          })*/
          /*
                     })*/

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
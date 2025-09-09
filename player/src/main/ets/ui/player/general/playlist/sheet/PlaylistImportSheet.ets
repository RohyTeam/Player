import { DialogHelper } from '@pura/harmony-dialog'
import { InnerContainer } from '../../../../component/inner/InnerContainer'
import { InnerComponentSet } from '../../../../component/inner/InnerComponentSet'
import { InnerButtonWithImage } from '../../../../component/inner/InnerButtonWithImage'
import { InnerDivider } from '../../../../component/inner/InnerDivider'
import { isEmptyOrBlank } from '../../../../../utils/StringUtils'
import { ComponentContent, promptAction } from '@kit.ArkUI'
import { PlaylistFolderItemsDataSource } from '../../../../../datasource/playlist/PlaylistFolderItemsDataSource'
import { pickSingleVideoFile } from '../../../../../utils/PickerUtils'
import { VideoMetadataManager } from '../../../../../metadata/VideoMetadataManager'
import { sha256 } from '../../../../../utils/HashUtils'
import { MetadataFetcher } from '../../../../../metadata/MetadataFetcher'
import { ensurePath, fileName } from '../../../../../utils/FileUtils'
import { fileShare } from '@kit.CoreFileKit'
import { ImportProgressContext, ImportProgressOverlayBuilder } from '../../../../overlay/ImportProgressOverlay'
import { VideoMetadata } from '../../../../../metadata/VideoMetadata'

@Concurrent
async function importVideo(path: string): Promise<VideoMetadata> {
  return await MetadataFetcher.fetch(path, false)
}

@ComponentV2
export struct PlaylistImportSheet {
  @Consumer("playlistFolderDataSource")
  playlistFolderDataSource?: PlaylistFolderItemsDataSource
  @Event
  hideChooser: () => void
  @Local
  importProgressContext: ImportProgressContext = new ImportProgressContext()

  build() {
    InnerContainer({
      bgColor: Color.Transparent,
      edgeEffect: false
    }) {
      InnerComponentSet() {
        InnerButtonWithImage({
          image: $r("app.media.hidisk_icon_video"),
          title: $r("app.string.import_video"),
          imageOutline: false,
          clickCallback: () => {
            if (!this.playlistFolderDataSource) {
              return
            }
            this.hideChooser()
            pickSingleVideoFile(this.getUIContext())
              .then(async (url) => {
                if (!url) {
                  return
                }
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
              })
          }
        })
        InnerDivider()
        InnerButtonWithImage({
          image: $r("app.media.hidisk_icon_folder"),
          title: $r("app.string.create_folder"),
          imageOutline: false,
          clickCallback: () => {
            if (!this.playlistFolderDataSource) {
              return
            }
            this.hideChooser()
            DialogHelper.showTextInputDialog({
              primaryTitle: $r("app.string.create_folder"),
              inputType: InputType.Normal,
              placeholder: $r("app.string.please_type_playlist_name"),
              cancelButton: {
                icon: {
                  color: $r("sys.color.icon_primary")
                }
              },
              defaultFocus: true,
              onAction: (action: number, dialogId: string, rawValue: string): void => {
                DialogHelper.closeDialog(dialogId)
                if (!this.playlistFolderDataSource) {
                  return
                }
                // clicked confirm
                if (action == -1) {
                  let value = rawValue.trim()
                  if (isEmptyOrBlank(value)) {
                    promptAction.showToast({
                      message: $r('app.string.name_cannot_be_blank')
                    })
                    return
                  }
                  if (this.playlistFolderDataSource.items().find((it) => it.name == value)) {
                    promptAction.showToast({
                      message: $r('app.string.name_duplicated')
                    })
                    return
                  }
                  this.playlistFolderDataSource.createFolder(value)
                  promptAction.showToast({
                    message: $r('app.string.create_success')
                  })
                }
              },
              buttons: [
                {
                  value: $r("app.string.confirm"),
                  fontColor: $r("sys.color.brand"),
                },
                {
                  value: $r("app.string.cancel")
                }
              ],
              text: ''
            })
          }
        })
      }
    }
  }
}
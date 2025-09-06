import { createSendableVideoMetadata, SendableVideoMetadata, sendableVideoMetadataToNormal } from './VideoMetadata'
import { collections, taskpool } from '@kit.ArkTS'
import { VideoMetadataManager } from './VideoMetadataManager'
import { FileSystem } from '../filemanagement/FileSystem'
import { SavedVideoMetadata, SendableSavedVideoMetadata } from './SavedVideoMetadata'
import { SendableSubtitleInfo, SubtitleInfo } from '../player/subtitle/SubtitleInfo'

@Concurrent
export function concurrentSave(
  tempDir: string,
  filesDir: string,
  identity: string,
  database: boolean,
  url: string,
  metadata: SendableVideoMetadata,
  headers: collections.Map<string, string>
) {
  let recordHeaders: Record<string, string> = {}
  if (headers) {
    for (let key of headers.keys()) {
      recordHeaders[key] = headers.get(key)!
    }
  }
  let savedMetadata = VideoMetadataManager.save(
    identity,
    database,
    url,
    sendableVideoMetadataToNormal(metadata),
    new FileSystem(tempDir, filesDir),
    recordHeaders
  )

  if (savedMetadata) {
    let subtitles: collections.Array<SendableSubtitleInfo> = new collections.Array()
    for (let subtitle of savedMetadata.subtitles) {
      subtitles.push(
        new SendableSubtitleInfo(
          subtitle.title,
          subtitle.language,
          subtitle.url,
          subtitle.type,
          subtitle.internal,
        )
      )
    }

    taskpool.Task.sendData(
      new SendableSavedVideoMetadata(
        createSendableVideoMetadata(savedMetadata.metadata),
        savedMetadata.identity,
        subtitles
      )
    )
  } else {
    taskpool.Task.sendData(undefined)
  }
}

export function asyncSave(
  tempDir: string,
  filesDir: string,
  identity: string,
  database: boolean,
  url: string,
  metadata: SendableVideoMetadata,
  headers?: collections.Map<string, string>
): Promise<SavedVideoMetadata | undefined> {
  return new Promise((resolver, reject) => {
    let task = new taskpool.LongTask(
      concurrentSave,
      tempDir,
      filesDir,
      identity,
      database,
      url,
      metadata,
      headers ?? new collections.Map<string, string>
    )
    task.onReceiveData((sendableSavedVideoMetadata: SendableSavedVideoMetadata | undefined) => {
      if (sendableSavedVideoMetadata) {
        let subtitleInfos: SubtitleInfo[] = []
        for (let subtitle of sendableSavedVideoMetadata.subtitles) {
          if (subtitle.type == "srt" || subtitle.type == "ass" || subtitle.type == "pgs") {
            subtitleInfos.push({
              title: subtitle.title,
              language: subtitle.language,
              url: subtitle.url,
              type: subtitle.type,
              internal: subtitle.internal,
            })
          }
        }
        resolver({
          metadata: sendableVideoMetadataToNormal(sendableSavedVideoMetadata.metadata),
          identity: sendableSavedVideoMetadata.identity,
          subtitles: subtitleInfos
        })
      } else {
        resolver(undefined)
      }
    })
    task.onExecutionFailed((err) => {
      reject(err)
    })
    taskpool.execute(task)
  })
}
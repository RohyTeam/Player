import { DialogHelper } from '@pura/harmony-dialog'
import { JSON } from '@kit.ArkTS'
import { InnerContainer } from '../../../../component/inner/InnerContainer'
import { InnerComponentSet } from '../../../../component/inner/InnerComponentSet'
import { InnerButtonWithImage } from '../../../../component/inner/InnerButtonWithImage'
import { InnerDivider } from '../../../../component/inner/InnerDivider'
import { isEmptyOrBlank } from '../../../../../utils/StringUtils'
import { promptAction } from '@kit.ArkUI'
import { PlaylistFolderItemsDataSource } from '../../../../../datasource/playlist/PlaylistFolderItemsDataSource'
import { pickSingleVideoFile } from '../../../../../utils/PickerUtils'
import { SavedVideoMetadata } from '../../../../../metadata/SavedVideoMetadata'
import { VideoMetadataManager } from '../../../../../metadata/VideoMetadataManager'
import { sha256 } from '../../../../../utils/HashUtils'
import { MetadataFetcher } from '../../../../../metadata/MetadataFetcher'
import { fileName } from '../../../../../utils/FileUtils'
import { fileShare } from '@kit.CoreFileKit'

@ComponentV2
export struct PlaylistImportSheet {

  @Consumer("playlistFolderDataSource")
  playlistFolderDataSource?: PlaylistFolderItemsDataSource

  @Event
  hideChooser: () => void

  build() {
    InnerContainer({
      bgColor: Color.Transparent
    }) {
      InnerComponentSet() {
        InnerButtonWithImage({
          image: $r("app.media.hidisk_icon_video"),
          title: $r("app.string.import_video"),
          imageOutline: false,
          clickCallback: () => {
            if (!this.playlistFolderDataSource)
              return
            this.hideChooser()
            pickSingleVideoFile(this.getUIContext())
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
                if (VideoMetadataManager.existsInTemp(identity)) {
                  await fileShare.persistPermission([{
                    uri: url,
                    operationMode: fileShare.OperationMode.READ_MODE
                  }])
                  VideoMetadataManager.tempToFile(identity)
                } else if (!VideoMetadataManager.exists(identity)) {
                  await fileShare.persistPermission([{
                    uri: url,
                    operationMode: fileShare.OperationMode.READ_MODE
                  }])
                  let metadata = await MetadataFetcher.fetch(url)
                  VideoMetadataManager.save(identity, true, url, metadata)
                }

                this.playlistFolderDataSource?.importVideo(fileName(url), identity, url)
              })
          }
        })
        InnerDivider()
        InnerButtonWithImage({
          image: $r("app.media.hidisk_icon_folder"),
          title: $r("app.string.create_folder"),
          imageOutline: false,
          clickCallback: () => {
            if (!this.playlistFolderDataSource)
              return
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
                if (!this.playlistFolderDataSource)
                  return
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
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
import { ImportProgressContext } from '../../../../overlay/ImportProgressOverlay'
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
            // TODO: readd when folders in playlist back
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
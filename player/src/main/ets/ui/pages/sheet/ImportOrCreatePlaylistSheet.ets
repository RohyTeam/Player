import { DialogHelper } from '@pura/harmony-dialog'
import { DataSources } from '../../../datasource/DataSources'
import { getIcon } from '../../../utils/ResourceUtils'
import { isEmptyOrBlank } from '../../../utils/StringUtils'
import { InnerButtonWithImage } from '../../component/inner/InnerButtonWithImage'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { InnerDivider } from '../../component/inner/InnerDivider'
import { JSON } from '@kit.ArkTS'
import { emptyPlaylistStructure } from '../../../playlist/PlaylistStructure'
import { promptAction } from '@kit.ArkUI'
import { InnerContainerText } from '../../component/inner/InnerContainerText'

@ComponentV2
export struct ImportOrCreatePlaylistSheet {
  @Event
  hideChooser: () => void

  build() {
    InnerContainer({
      bgColor: Color.Transparent
    }) {
      InnerComponentSet() {
        InnerButtonWithImage({
          image: $r("app.media.hidisk_icon_folder"),
          title: $r("app.string.create_playlist"),
          imageOutline: false,
          clickCallback: () => {
            this.hideChooser()
            DialogHelper.showTextInputDialog({
              primaryTitle: $r("app.string.create_playlist"),
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
                // clicked confirm
                if (action == -1) {
                  let value = rawValue.trim()
                  if (isEmptyOrBlank(value)) {
                    promptAction.showToast({
                      message: $r('app.string.name_cannot_be_blank')
                    })
                    return
                  }
                  if (DataSources.PLAYLIST.all().find((it) => it.name == value)) {
                    promptAction.showToast({
                      message: $r('app.string.name_duplicated')
                    })
                    return
                  }
                  DataSources.PLAYLIST.add({
                    name: value,
                    structure: JSON.stringify(emptyPlaylistStructure()),
                    updatedAt: Date.now()
                  }, false)
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

      InnerContainerDivider()
      InnerContainerText({
        text: $r("app.string.not_implemented_below"),
        textColor: $r("sys.color.font_secondary")
      })
      InnerComponentSet() {
        InnerButtonWithImage({
          image: getIcon($r("app.media.filemanager_icon")),
          title: $r("app.string.import_folder"),
          subtitle: $r("app.string.pc_tablet_only"),
          imageOutline: false,
          clickCallback: () => {
          }
        })
        InnerDivider()
        InnerButtonWithImage({
          image: getIcon($r("app.media.webdav_icon")),
          title: $r("app.string.import_webdav"),
          clickCallback: () => {
          }
        })
      }
    }
  }
}
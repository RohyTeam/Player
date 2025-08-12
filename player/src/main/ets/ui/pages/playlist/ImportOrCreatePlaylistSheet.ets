import { PickedFile } from '../../../filemanagement/PickedFile'
import { getIcon } from '../../../utils/ResourceUtils'
import { InnerButtonWithImage } from '../../component/inner/InnerButtonWithImage'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { InnerDivider } from '../../component/inner/InnerDivider'

@ComponentV2
export struct ImportOrCreatePlaylistSheet {
  @Event
  hideChooser: () => void = () => {
  }
  @Event
  onPick: (files: PickedFile[]) => void = () => {
  }

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
          }
        })
      }
      InnerContainerDivider()
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
import { PickedFile } from '../../../filemanagement/PickedFile'
import { getIcon } from '../../../utils/ResourceUtils'
import { InnerButtonWithImage } from '../../component/inner/InnerButtonWithImage'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { InnerDivider } from '../../component/inner/InnerDivider'

@ComponentV2
export struct ImportVideoSheet {
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
          image: getIcon($r("app.media.filemanager_icon")),
          title: $r("app.string.create_folder"),
          imageOutline: false,
          clickCallback: () => {
          }
        })
      }

      InnerContainerDivider()
      InnerComponentSet() {
        InnerButtonWithImage({
          image: getIcon($r("app.media.filemanager_icon")),
          title: $r("app.string.file_manager"),
          imageOutline: false,
          showGoToIcon: true,
          clickCallback: () => {
          }
        })
        InnerDivider()
        InnerButtonWithImage({
          image: getIcon($r("app.media.photos_icon")),
          title: $r("app.string.images"),
          showGoToIcon: true,
          clickCallback: () => {
          }
        })
      }
    }
  }
}
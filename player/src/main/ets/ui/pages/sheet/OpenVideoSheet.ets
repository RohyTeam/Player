import { LocalFiles, Photos } from '../../../filemanagement/FileSource'
import { PickedFile } from '../../../filemanagement/PickedFile'
import { pickPhotosVideoFiles, pickVideoFiles } from '../../../utils/PickerUtils'
import { getIcon } from '../../../utils/ResourceUtils'
import { InnerButtonWithImage } from '../../component/inner/InnerButtonWithImage'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerDivider } from '../../component/inner/InnerDivider'

@ComponentV2
export struct OpenVideoSheet {
  @Event
  hideChooser: () => void = () => {
  }
  @Event
  onPick: (files: PickedFile) => void = () => {
  }

  build() {
    InnerContainer({
      bgColor: Color.Transparent
    }) {
      InnerComponentSet() {
        InnerButtonWithImage({
          image: getIcon($r("app.media.filemanager_icon")),
          title: $r("app.string.file_manager"),
          imageOutline: false,
          showGoToIcon: true,
          clickCallback: () => {
            this.hideChooser()
            pickVideoFiles(this.getUIContext(), 1)
              .then((urls) => {
                if (urls.length == 0) {
                  return
                }
                this.onPick({
                  source: LocalFiles,
                  url: urls[0]
                })
              })
          }
        })
        InnerDivider()
        InnerButtonWithImage({
          image: getIcon($r("app.media.photos_icon")),
          title: $r("app.string.images"),
          showGoToIcon: true,
          clickCallback: () => {
            this.hideChooser()
            pickPhotosVideoFiles(this.getUIContext(), 1)
              .then((assets) => {
                if (assets.length == 0) {
                  return
                }
                this.onPick({
                  source: Photos,
                  url: assets[0].uri,
                  title: assets[0].displayName
                })
              })
          }
        })
      }
    }
  }
}
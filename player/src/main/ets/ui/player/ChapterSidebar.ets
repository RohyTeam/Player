import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { Modifiers } from '../attributemodifier/Modifiers'
import { SymbolGlyphModifier } from '@kit.ArkUI'
import { ChapterInfo } from '../../player/chapter/ChapterInfo'
import { InnerContainer } from '../component/inner/InnerContainer'
import { InnerContainerDivider } from '../component/inner/InnerContainerDivider'
import { InnerComponentSet } from '../component/inner/InnerComponentSet'
import { InnerButton } from '../component/inner/InnerButton'
import { convertNumberToDurationString } from '../../utils/NumberUtils'
import { ControlsContext } from './PlayerBottomBar'

@ComponentV2
export struct ChapterSidebar {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Consumer("controlsContext")
  controlsContext: ControlsContext = new ControlsContext()

  build() {
    Navigation() {
      InnerContainer({
        bgColor: Color.Transparent,
        staticBottomAvoid: false
      }) {
        ForEach(this.playerContext.chapters, (chapter: ChapterInfo, index: number) => {
          InnerContainerDivider()
          InnerComponentSet() {
            InnerButton({
              title: chapter.title,
              subtitle: `${convertNumberToDurationString(chapter.start)} - ${convertNumberToDurationString(chapter.end)}`,
              italic: typeof chapter.title != 'string',
              clickCallback: () => {
                this.playerController.seek(chapter.start)
              }
            })
          }
        })
      }
    }
    .width("100%")
    .height("100%")
    .attributeModifier(Modifiers.backgroundBlur())
    .hideBackButton(true)
    .hideToolBar(true)
    .menus([
      {
        value: "close",
        symbolIcon: new SymbolGlyphModifier($r("sys.symbol.xmark")),
        action: () => {
          this.controlsContext.showChapterList = false
        }
      }
    ])
    .title($r("app.string.chapter_list"))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}
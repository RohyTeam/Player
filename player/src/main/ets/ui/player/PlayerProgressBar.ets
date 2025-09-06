import { ChapterInfo } from '../../player/chapter/ChapterInfo'
import { PlayerContext } from '../../player/PlayerContext'
import { PlayerController } from '../../player/PlayerController'
import { convertNumberToDurationString } from '../../utils/NumberUtils'

@ComponentV2
export struct PlayerProgressBar {
  @Consumer("playerController")
  playerController: PlayerController = new PlayerController()
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  build() {
    Row() {
      if (this.playerContext.video) {
        this.videoProgressBar()
      } else {
        this.nonVideoProgressBar()
      }
    }
    .width("100%")
  }

  @Builder
  private videoProgressBar() {
    Text(`${convertNumberToDurationString(this.playerContext.currentPosition)}`)
      .margin({
        left: 16,
        right: 4
      })
      .fontColor($r("sys.color.font_secondary"))
    Stack() {
      Slider({
        min: 0,
        max: this.playerContext.maxDuration,
        step: 1,
        value: this.playerContext.targetPosition
      })
        .enabled(false)
        .blockSize({
          width: 1,
          height: 1
        })
        .blockColor(Color.Transparent)
        .blockBorderColor(Color.Transparent)
        .width("100%")
      Column() {
        Stack() {
          ForEach(this.playerContext.chapters, (chapter: ChapterInfo) => {
            Row() {
              Blank()
                .layoutWeight(chapter.start)
              SymbolGlyph($r('sys.symbol.bookmark_fill'))
                .fontColor([$r('sys.color.icon_primary')])
                .fontSize(8)
                .width(8)
                .height(8)
              Blank()
                .layoutWeight(chapter.end - chapter.start)
              // todo: 暂时不显示章节末尾的标，没有必要，先当作占位符
              SymbolGlyph($r('sys.symbol.bookmark_fill'))
                .fontColor([$r('sys.color.icon_primary')])
                .fontSize(8)
                .width(8)
                .height(8)
                .visibility(Visibility.Hidden)
              Blank()
                .layoutWeight(this.playerContext.maxDuration - chapter.end)
            }
            .width("100%")
          })
        }
        .width("100%")
      }
      .width("100%")

      Slider({
        min: 0,
        max: this.playerContext.maxDuration,
        step: 1,
        value: this.playerContext.targetPosition
      })
        .onChange((value, mode: SliderChangeMode) => {
          if (mode == SliderChangeMode.Begin) {
            this.playerController.startMovingPosition()
          } else if (mode == SliderChangeMode.End) {
            this.playerController.seekTarget()
            this.playerController.stopMovingPosition()
          } else if (mode == SliderChangeMode.Click) {
            this.playerController.seek(value)
          } else if (mode == SliderChangeMode.Moving) {
            this.playerContext.targetPosition = value
          }
        })
        .trackColor(Color.Transparent)
        .selectedColor(Color.Transparent)
        .stepColor(Color.Transparent)
        .width("100%")
    }
    .layoutWeight(1)

    Text(`${convertNumberToDurationString(this.playerContext.maxDuration)}`)
      .margin({
        left: 4,
        right: 16
      })
      .fontColor($r("sys.color.font_secondary"))
  }

  @Builder
  private nonVideoProgressBar() {
    Text(`**:**`)
      .margin({
        left: 16,
        right: 4
      })
      .fontColor($r("sys.color.font_secondary"))
    Slider({
      min: 0,
      max: 0,
      step: 1,
      value: 0
    })
      .enabled(false)
      .layoutWeight(1)
    Text(`**:**`)
      .margin({
        left: 4,
        right: 16
      })
      .fontColor($r("sys.color.font_secondary"))
  }
}
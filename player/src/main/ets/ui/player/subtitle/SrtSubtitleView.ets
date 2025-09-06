import { parseSrtSubtitle, SrtSubtitleLine } from '../../../lib/subtitle/srt/srt';
import { PlayerContext } from '../../../player/PlayerContext';
import { fileIo } from '@kit.CoreFileKit';
import { ensurePath } from '../../../utils/FileUtils';
import { LengthMetricsUnit } from '@kit.ArkUI';

// FIXME: 由于使用 canvas 绘制，假如同一时间有多行字幕，将会重叠到一起
@ComponentV2
export struct SrtSubtitleView {
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Local
  subtitles: SrtSubtitleLine[] = []

  aboutToAppear(): void {
    fileIo.readText(ensurePath(this.playerContext.subtitles[this.playerContext.selectedSubtitle!].url))
      .then((text) => {
        this.subtitles = parseSrtSubtitle(text)
      })
  }

  build() {
    Stack() {
      Column() {
        ForEach(this.subtitles, (subtitleLine: SrtSubtitleLine) => {
          if (subtitleLine.start <= this.playerContext.currentPosition &&
            subtitleLine.end >= this.playerContext.currentPosition) {
            SubtitleLine({
              text: subtitleLine.text,
              playerContext: this.playerContext
            })
          }
        })
      }
      .width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
  }
}

@ComponentV2
export struct SubtitleLine {
  @Param
  @Require
  text: string
  @Param
  @Require
  playerContext: PlayerContext
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.context.font = "16vp"

        let textMetrics = this.context.measureText(this.text)

        let x = (this.playerContext.playerWidthPx - textMetrics.width) / 2
        let y = this.playerContext.playerHeightPx - 16

        this.context.fillStyle = "#ffffff"
        this.context.strokeStyle = "#000000"

        this.context.lineWidth = 3
        this.context.strokeText(this.text, x, y)
        this.context.lineWidth = 1
        this.context.fillText(this.text, x, y)
      })
  }
}
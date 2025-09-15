import { PlayerContext } from '../../../player/PlayerContext';
import { ensurePath } from '../../../utils/FileUtils';
import { LengthMetricsUnit } from '@kit.ArkUI';
import { ParseVtt, VttLine } from '@dove/subtitles'

@ComponentV2
export struct VttSubtitleView {
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Local
  subtitles: VttLine[] = []

  aboutToAppear(): void {
    let parser = new ParseVtt(ensurePath(this.playerContext.subtitles[this.playerContext.selectedSubtitle!].url))
    parser.init()
      .then(() => {
        parser.readLines()
          .then((lines) => {
            this.subtitles = lines
          })
      })
  }

  build() {
    Stack() {
      Column() {
        Blank()
          .layoutWeight(1)
        ForEach(this.subtitles, (subtitleLine: VttLine) => {
          if (subtitleLine.start.getTime() <= this.playerContext.currentPosition &&
            subtitleLine.end.getTime() >= this.playerContext.currentPosition) {
            SubtitleLine({
              text: subtitleLine.text,
              playerContext: this.playerContext
            })
          }
        })
        Blank()
          .height(16)
      }
      .alignItems(HorizontalAlign.Center)
      .width("100%")
      .height("100%")
    }
    .width("100%")
    .height("100%")
  }
}

@ComponentV2
struct SubtitleLine {
  @Param
  @Require
  text: string
  @Param
  @Require
  playerContext: PlayerContext
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  @Local
  private canvasWidth: number = 1
  @Local
  private canvasHeight: number = 1

  aboutToAppear() {
    // 这里先提前初始化一下，防止绘制内容超出被裁切
    this.canvasWidth = this.playerContext.playerWidthPx
    this.canvasHeight = this.playerContext.playerHeightPx
  }

  build() {
    Canvas(this.context)
      .width(this.canvasWidth)
      .height(this.canvasWidth)
      .onReady(() => {
        this.context.font = "16vp"
        this.context.fillStyle = "#ffffff"
        this.context.strokeStyle = "#000000"

        let realText = this.text

        while (realText.endsWith("<i>") || realText.endsWith("<b>"))
          realText = realText.substring(0, realText.length - 3)

        let x = 0
        let y = 4

        let textMetrics = this.context.measureText(this.text)

        this.canvasWidth = textMetrics.width
        this.canvasHeight = 24

        this.context.lineWidth = 3
        this.context.strokeText(this.text, x, y)
        this.context.lineWidth = 1
        this.context.fillText(this.text, x, y)
      })
  }

}
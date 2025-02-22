import { SubtitleEntity } from "../../entity/SubtitleEntity"
import { SrtSubtitleLine } from "../../lib/srt/srt"
import { LengthMetricsUnit } from "@kit.ArkUI"

@Component
export struct SimpleSrtSubtitleView {

  @Prop
  subtitle: SubtitleEntity
  @Prop
  currentTime: number
  @Prop
  actualWidth: number
  @Prop
  actualHeight: number

  build() {
    Stack() {
      Column() {
        ForEach(this.subtitle.extra as SrtSubtitleLine[], (subtitleLine: SrtSubtitleLine) => {
          if (subtitleLine.start <= this.currentTime && subtitleLine.end >= this.currentTime) {
            SubtitleLine({
              text: subtitleLine.text,
              actualWidth: this.actualWidth,
              actualHeight: this.actualHeight
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

@Component
export struct SubtitleLine {

  @Prop
  text: string
  @Prop
  actualWidth: number
  @Prop
  actualHeight: number

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        let textMetrics = this.context.measureText(this.text)

        let x = (this.actualWidth - textMetrics.width) / 2
        let y = this.actualHeight - 16

        this.context.fillStyle = "#ffffff"
        this.context.strokeStyle = "#000000"

        this.context.lineWidth = 3
        this.context.strokeText(this.text, x, y)
        this.context.lineWidth = 1
        this.context.fillText(this.text, x, y)
      })
  }

}
import { LengthMetricsUnit } from "@kit.ArkUI"
import { RohyPgsSubtitleRenderer } from "librohy_subtitle.so"
import { PlayerContext } from "../../../player/PlayerContext"
import { fileIo } from "@kit.CoreFileKit"
import { rgbaBufferToPixelMap } from "../../../utils/ImageUtils"
import { JSON, taskpool } from "@kit.ArkTS"
import { PgsSubtitleImage } from "../../../player/subtitle/PgsSubtitleImage"
import { superContext } from "../../../utils/AbilityUtils"
import { ensurePath } from "../../../utils/FileUtils"

@Concurrent
function createAndInitPgsRenderer(filePath: string): RohyPgsSubtitleRenderer {
  let renderer = new RohyPgsSubtitleRenderer()
  renderer.init(filePath)
  return renderer
}

@ComponentV2
export struct PgsSubtitleView {

  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  private subtitleRenderer: RohyPgsSubtitleRenderer = new RohyPgsSubtitleRenderer()

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  @Local
  ready: boolean = false
  @Local
  closed: boolean = false

  aboutToAppear(): void {
    fileIo.access(superContext().filesDir, fileIo.AccessModeType.EXIST)
      .then(() => {
        // 为了防止卡住 UI，随便找一个异步线程来执行初始化操作
        this.subtitleRenderer.init(ensurePath(this.playerContext.subtitles[this.playerContext.selectedSubtitle!].url))

        if (this.closed) {
          this.subtitleRenderer.release()
          return
        }

        this.playerContext.subtitlePositionUpdater = (position: number) => {
          if (!this.ready)
            return

          let images = this.subtitleRenderer.render(position) as PgsSubtitleImage[] | undefined
          this.context.reset()
          if (images == undefined)
            return
          for (let pgsSubtitleImage of images) {
            let pixelMap = rgbaBufferToPixelMap(pgsSubtitleImage.buffer, pgsSubtitleImage.width, pgsSubtitleImage.height)
            if (!pixelMap)
              continue

            let widthRatio = this.playerContext.playerWidthPx / pgsSubtitleImage.screenWidth
            let heightRatio = this.playerContext.playerHeightPx / pgsSubtitleImage.screenHeight

            let width = pgsSubtitleImage.width * widthRatio
            let height = pgsSubtitleImage.height * heightRatio
            let x = pgsSubtitleImage.x * widthRatio
            let y = pgsSubtitleImage.y * heightRatio

            pixelMap.scaleSync(widthRatio, heightRatio)

            this.context.drawImage(
              pixelMap,
              x,
              y,
              width,
              height
            )
          }
        }
      })
      .catch((err: Error) => {
        console.error(`error occurs: ${err.message}`)
      })
  }

  aboutToDisappear(): void {
    this.closed = true
    this.subtitleRenderer.release()
    this.playerContext.subtitlePositionUpdater = () => {}
  }

  build() {
    Canvas(this.context)
      .onReady(() => {
        this.ready = true
      })
      .width("100%")
      .height("100%")
  }

}
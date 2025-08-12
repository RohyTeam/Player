import { LengthMetricsUnit } from "@kit.ArkUI"
import { RohyAssSubtitleRenderer } from "librohy_subtitle.so"
import { PlayerContext } from "../../../../player/PlayerContext"
import { fileIo } from "@kit.CoreFileKit"
import { AssSubtitleImage } from "../../../../subtitle/AssSubtitleImage"
import { rgbaBufferToPixelMap } from "../../../../utils/imageUtils"
import { JSON } from "@kit.ArkTS"

@ObservedV2
class Images extends Array<AssSubtitleImage> {
}

@ComponentV2
export struct AssSubtitleView {

  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  private subtitleRenderer: RohyAssSubtitleRenderer = new RohyAssSubtitleRenderer()

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  @Local
  ready: boolean = false

  @Local
  images: Images = []

  aboutToAppear(): void {
    getContext(this).resourceManager.getRawFileContent('HarmonyOS_Sans_SC_Regular.ttf')
      .then((data) => {
        this.subtitleRenderer.addMemoryFont(
          "HarmonyOS Sans SC",
          data.buffer
        )

        let file = fileIo.openSync(this.playerContext.subtitles[this.playerContext.selectedSubtitle!].url)
        const arrayBuffer = new ArrayBuffer(fileIo.statSync(file.fd).size);
        fileIo.readSync(file.fd, arrayBuffer)
        fileIo.close(file)
        this.subtitleRenderer.init(arrayBuffer)

        this.playerContext.subtitlePositionUpdater = (position: number) => {
          if (!this.ready)
            return

          console.error(`player width: ${this.playerContext.playerWidthPx}, height: ${this.playerContext.playerHeightPx}`)
          this.images = this.subtitleRenderer.render(
            position,
            this.playerContext.playerWidthPx,
            this.playerContext.playerHeightPx
          ) as AssSubtitleImage[]

          this.context.reset()

          for (let image of this.images) {
            let pixelMap = rgbaBufferToPixelMap(image.buffer, image.width, image.height)
            if (!pixelMap)
              continue
            this.context.drawImage(
              pixelMap,
              image.x,
              image.y,
              image.width,
              image.height
            )
          }
        }
      })
      .catch((err: Error) => {
        console.error(`error occurs: ${err.message}`)
      })
  }

  aboutToDisappear(): void {
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
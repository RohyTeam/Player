import { LengthMetricsUnit } from '@kit.ArkUI'
import { SendableRohyPgsSubtitleRenderer } from 'librohy_subtitle.so'
import { PlayerContext } from '../../../player/PlayerContext'
import { rgbaBufferToPixelMap } from '../../../utils/ImageUtils'
import { ISendablePgsSubtitleImage } from '../../../player/subtitle/PgsSubtitleImage'
import { ensurePath } from '../../../utils/FileUtils'
import { taskpool } from '@kit.ArkTS'
import { arrayBufferCollectionsToES5 } from '../../../utils/ArkTSCollectionsUtils'
import { PgsSubtitleRange } from '../../../subtitle/PgsSubtitle'


@Concurrent
function createAndInitPgsRenderer(renderer: SendableRohyPgsSubtitleRenderer, filePath: string) {
  taskpool.Task.sendData(renderer.sendableInit(filePath))
}

class PgsSubtitleRanges extends Array<PgsSubtitleRange> {
}

@ComponentV2
export struct PgsSubtitleView {
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)
  @Local
  ready: boolean = false
  @Local
  closed: boolean = false
  @Local
  subtitles: PgsSubtitleRanges = []
  @Provider("renderer")
  private renderer: SendableRohyPgsSubtitleRenderer = new SendableRohyPgsSubtitleRenderer()

  aboutToAppear(): void {
    let path = ensurePath(this.playerContext.subtitles[this.playerContext.selectedSubtitle!].url)
    let task = new taskpool.LongTask(createAndInitPgsRenderer, this.renderer, path)
    task.onReceiveData((ranges: PgsSubtitleRange[]) => {
      for (let range of ranges) {
        this.subtitles.push(range)
      }
    })
    taskpool.execute(task)
  }

  aboutToDisappear(): void {
    this.closed = true
    this.renderer.sendableRelease()
  }

  build() {
    Stack() {
      ForEach(this.subtitles, (range: PgsSubtitleRange) => {
        // 由于 PGS 实现机制导致，可能会存在延迟，所有将 pgs 字幕显示调整为提前半秒
        if (range.start - 500 <= this.playerContext.currentPosition &&
          range.end - 500 >= this.playerContext.currentPosition) {
          PgsSubtitle({
            subtitle: range
          })
        }
      })
    }
    .width("100%")
    .height("100%")
  }
}

@ComponentV2
struct PgsSubtitle {
  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())
  @Consumer("renderer")
  private renderer: SendableRohyPgsSubtitleRenderer = new SendableRohyPgsSubtitleRenderer()
  @Param
  @Require
  subtitle: PgsSubtitleRange
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  build() {
    Canvas(this.context)
      .onReady(() => {
        let images = this.renderer.sendableRenderByIndex(this.subtitle.index) as ISendablePgsSubtitleImage[] | undefined
        this.context.reset()
        if (images == undefined) {
          return
        }

        for (let pgsSubtitleImage of images) {
          let pixelMap =
            rgbaBufferToPixelMap(arrayBufferCollectionsToES5(pgsSubtitleImage.buffer), pgsSubtitleImage.width,
              pgsSubtitleImage.height)
          if (!pixelMap) {
            continue
          }

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
      })
      .width("100%")
      .height("100%")
  }
}
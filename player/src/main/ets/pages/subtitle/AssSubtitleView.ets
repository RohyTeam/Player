import { CompiledASS } from '../../lib/ass_compiler';
import { LengthMetricsUnit } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import SubtitleManager from 'librohy_subtitle.so';

interface SubtitleImage {
  buffer: ArrayBuffer;
  width: number;
  height: number;
  x: number;
  y: number;
}

@Observed
export class SubtitleController {
  private positioner: (position: number) => void = () => {
    console.error(`fallback positioner executed`)
  }

  initPositioner(newPositioner: (position: number) => void) {
    console.error(`changing new positioner`)
    this.positioner = newPositioner
  }

  seek(position: number) {
    this.positioner(position)
  }
}

@Observed
class Images extends Array<SubtitleImage> {
}

@Component
export struct NativeAssSubtitleView {
  @Prop
  path: string
  @Prop
  actualWidth: number
  @Prop
  actualHeight: number
  @Prop
  metadata: CompiledASS
  @Link
  controller: SubtitleController
  @State
  ready: boolean = false
  @State
  debug: boolean = false
  @State
  images: Images = new Images()

  aboutToAppear(): void {
    getContext(this).resourceManager.getRawFileContent('HarmonyOS_Sans_SC_Regular.ttf')// fallback 字体，TODO: 字体管理实现字体加载
      .then((data) => {
        SubtitleManager.Subtitle_AddMemoryFont("HarmonyOS Sans SC", data.buffer)
        fileIo.open(this.path)
          .then((file) => {
            console.error("SHIT: init")
            const arrayBuffer = new ArrayBuffer(fileIo.statSync(file.fd).size);
            fileIo.readSync(file.fd, arrayBuffer)
            console.error("SHIT: read all bytes")
            SubtitleManager.Subtitle_Init(arrayBuffer)
            this.controller.initPositioner((position: number) => {
              console.error("SHIT: render")
              this.images =
                SubtitleManager.Subtitle_Render(position, this.actualWidth, this.actualHeight) as SubtitleImage[]
              if (this.ready) {
                this.context.reset()
                for (let subtitleImage of this.images) {

                  let pixelMap = image.createPixelMapSync(subtitleImage.buffer, {
                    srcPixelFormat: image.PixelMapFormat.RGBA_8888,
                    pixelFormat: image.PixelMapFormat.RGBA_8888,
                    alphaType: image.AlphaType.UNPREMUL,
                    size: {
                      width: subtitleImage.width,
                      height: subtitleImage.height
                    }
                  })
                  if (pixelMap) {
                    console.error(`rendering image at ${subtitleImage.x}, ${subtitleImage.y}`)
                    // DeepSeek 老师竟然是对的，这玩意还真得用 canvas 绘制，不然字幕会整个被放大糊满整个屏幕
                    this.context.drawImage(pixelMap, subtitleImage.x, subtitleImage.y, subtitleImage.width,
                      subtitleImage.height);
                  }
                }
              }
            })
          })
      })
  }

  aboutToDisappear(): void {
    this.controller.initPositioner(() => {
    }) // clear positioner to prevent crashing due to release the ass track
    SubtitleManager.Subtitle_Release()
  }

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  build() {
    Stack() {
      Canvas(this.context)
        .onReady(() => {
          this.ready = true
        })
        .width("100%")
        .height("100%")
    }
    .width("100%")
    .height("100%")
  }
}
import { VideoSource, VideoSourceType } from "./VideoSource";
import { media } from "@kit.MediaKit";
import { SurfaceFillingMode } from "./SurfaceFillingMode";
import { AppStorageV2, PersistenceV2 } from "@kit.ArkUI";

export interface Player {

  prepare(context: object, controller: XComponentController, source: VideoSource): void

  onPositionChange(callback: (time: number) => void): void
  onSeekComplete(callback: (time: number) => void): void

  getFillingMode(): SurfaceFillingMode
  setFillingMode(mode: SurfaceFillingMode): void

}

abstract class AbstractPlayer implements Player {

  protected onPositionChangeCallback: (time: number) => void = () => {}
  protected onSeekCompleteCallback: (time: number) => void = () => {}

  abstract prepare(context: object, controller: XComponentController, source: VideoSource): void

  onPositionChange(callback: (time: number) => void): void {
    this.onPositionChangeCallback = callback
  }

  onSeekComplete(callback: (time: number) => void): void {
    this.onSeekCompleteCallback = callback
  }

  setFillingMode(mode: SurfaceFillingMode): void {
    PersistenceV2.remove("surface_filling_mode")
    PersistenceV2.connect(Number, "surface_filling_mode", () => mode)
  }

  getFillingMode(): SurfaceFillingMode {
    let value = PersistenceV2.connect(Number, "surface_filling_mode", () => SurfaceFillingMode.Fit)
    if (value == SurfaceFillingMode.Stretch) {
      return SurfaceFillingMode.Stretch
    } else if (value == SurfaceFillingMode.FourToThree) {
      return SurfaceFillingMode.FourToThree
    } else if (value == SurfaceFillingMode.SixteenToNine) {
      return SurfaceFillingMode.SixteenToNine
    }
    return SurfaceFillingMode.Fit
  }

}

export class AvPlayer extends AbstractPlayer {

  private avPlayer: media.AVPlayer | undefined = undefined

  async prepare(context: object, controller: XComponentController, source: VideoSource): Promise<void> {
    if (source.type() != VideoSourceType.Photos)
      throw Error("av player only supports videos from photos")

    source.prepare()

    let avPlayer = this.avPlayer = await media.createAVPlayer()
    avPlayer.surfaceId = controller.getXComponentSurfaceId()

    // 下面所有的监听器都不要直接把 callback 传进去，要不然修改了 callback 后 AVPlayer 的回调仍然是原来的
    avPlayer.on('timeUpdate', (time) => {
      this.onPositionChangeCallback(time)
    })
    avPlayer.on('seekDone', (time) => {
      this.onSeekCompleteCallback(time)
    })
  }

}
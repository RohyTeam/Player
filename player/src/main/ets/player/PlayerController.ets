import { Player } from "./Player";
import { SurfaceFillingMode } from "./SurfaceFillingMode";

@ObservedV2
export class PlayerController {

  private player: Player | undefined = undefined

  play(): void {
    this.player?.play()
  }

  pause(): void {
    this.player?.pause()
  }

  release(): void {
    this.player?.release()
    this.player = undefined
  }

  seek(time: number) {
    this.player?.seek(time)
  }

  selectTrack(index: number): void {
    this.player?.selectTrack(index)
  }

  deselectTrack(index: number): void {
    this.player?.deselectTrack(index)
  }

  getFillingMode(): SurfaceFillingMode {
    return this.player?.getFillingMode() ?? SurfaceFillingMode.Fit
  }

  setFillingMode(mode: SurfaceFillingMode): void {
    this.player?.setFillingMode(mode)
  }

  isHardwareEncoding(): boolean {
    return this.player?.isHardwareEncoding() ?? false
  }

  enableHardwareEncoding(): void {
    this.player?.enableHardwareEncoding()
  }

  disableHardwareEncoding(): void {
    this.player?.disableHardwareEncoding()
  }

  initPlayer(player: Player) {
    this.player = player
  }

}
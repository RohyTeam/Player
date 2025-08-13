import { BackgroundTaskContext } from '../context/BackgroundTaskContext';
import { WindowContext } from '../context/WindowContext';
import { Player } from './Player';
import { SurfaceFillingMode } from './SurfaceFillingMode';

@ObservedV2
export class PlayerController {
  private player: Player | undefined = undefined

  playOrPause(): void {
    if (!this.player) {
      return
    }
    if (this.player.isPaused()) {
      this.play()
    } else {
      this.pause()
    }
  }

  getWindowContext(): WindowContext | undefined {
    return this.player?.getWindowContext()
  }

  startAdjustingScreenBrightness() {
  }
  stopAdjustingScreenBrightness() {
  }
  startAdjustingVolume() {
  }
  stopAdjustingVolume() {
  }

  increaseScreenBrightness(brightness: number) {

  }

  decreaseScreenBrightness(brightness: number) {

  }

  increaseVolume(brightness: number) {

  }

  decreaseVolume(brightness: number) {

  }

  setSpeed(speed: number) {
    if (!this.player) {
      return
    }
    this.player?.setSpeed(speed)
  }

  startLongPressSpeeding() {
    this.player?.startLongPressSpeeding()
  }

  stopLongPressSpeeding() {
    this.player?.stopLongPressSpeeding()
  }

  play(): void {
    if (!this.player)
      return
    BackgroundTaskContext.startBackgroundTask(this.player.getContext(), this)
    this.player.play()
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

  goBackward(delta: number) {
    if (!this.player) {
      return
    }
    this.player.seek(Math.max(this.player.currentPosition() - delta, 0))
  }

  goForward(delta: number) {
    if (!this.player) {
      return
    }
    this.player.seek(Math.min(this.player.currentPosition() + delta, this.player.maxDuration()))
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
import { BackgroundTaskContext } from '../context/BackgroundTaskContext';
import { Sys } from '../context/SystemContext';
import { WindowContext } from '../context/WindowContext';
import { clamp } from '../utils/MathUtils';
import { Player } from './Player';
import { PlayerContext } from './PlayerContext';
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

  getPlayerContext(): PlayerContext | undefined {
    return this.player?.getPlayerContext()
  }

  startMovingPosition() {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.movingPosition = true
  }

  stopMovingPosition() {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.movingPosition = false
  }

  startAdjustingScreenBrightness() {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.adjustingScreenBrightness = true
  }

  stopAdjustingScreenBrightness() {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.adjustingScreenBrightness = false
  }

  startAdjustingVolume() {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.adjustingVolume = true
  }

  stopAdjustingVolume() {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.adjustingVolume = false
  }

  increaseScreenBrightness(brightness: number) {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.currentScreenBrightness =
      Math.min(255, Math.max(0, this.getPlayerContext()!.currentScreenBrightness + brightness))
    this.getWindowContext()!.window!.setWindowBrightness(clamp(this.getPlayerContext()!.currentScreenBrightness / 255, 0,
      1)).then(() => {
    })
  }

  decreaseScreenBrightness(brightness: number) {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.currentScreenBrightness =
      Math.min(255, Math.max(0, this.getPlayerContext()!.currentScreenBrightness - brightness))
    this.getWindowContext()!.window!.setWindowBrightness(clamp(this.getPlayerContext()!.currentScreenBrightness / 255, 0,
      1)).then(() => {
    })
  }

  increaseVolume(volume: number) {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.currentVolume =
      Math.min(Sys.maxVolume, Math.max(Sys.minVolume, this.getPlayerContext()!.currentVolume + volume))
  }

  decreaseVolume(volume: number) {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.currentVolume =
      Math.min(Sys.maxVolume, Math.max(Sys.minVolume, this.getPlayerContext()!.currentVolume - volume))
  }

  setSpeed(speed: number) {
    if (!this.player) {
      return
    }
    this.player?.setSpeed(speed)
  }

  startLongPressSpeeding() {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.speedingUp = true
    this.player?.startLongPressSpeeding()
  }

  stopLongPressSpeeding() {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.speedingUp = false
    this.player?.stopLongPressSpeeding()
  }

  play(): void {
    if (!this.player) {
      return
    }
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

  seekTarget() {
    if (!this.player) {
      return
    }
    this.player?.seek(this.getPlayerContext()!.targetPosition)
  }

  goBackward(delta: number) {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.lastTimeBackward = Date.now()
    this.player.seek(Math.max(this.player.currentPosition() - delta, 0))
  }

  goForward(delta: number) {
    if (!this.player) {
      return
    }
    this.getPlayerContext()!.lastTimeForward = Date.now()
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
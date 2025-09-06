import { VideoSource, VideoSourceType } from './VideoSource';
import { media } from '@kit.MediaKit';
import { SurfaceFillingMode } from './SurfaceFillingMode';
import { AbilityStorage } from '../storage/AbilityStorage';
import { PlayerContext } from './PlayerContext';
import { IjkMediaPlayer } from '@ohos/ijkplayer';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { Win, WindowContext } from '../context/WindowContext';

export interface Player {

  isPaused(): boolean

  play(): void

  pause(): void

  release(): void

  prepare(abilityContext: Context, context: object | undefined, controller: XComponentController,
    source: VideoSource): void

  currentPosition(): number

  maxDuration(): number

  seek(time: number): void

  startLongPressSpeeding(): void

  stopLongPressSpeeding(): void

  setSpeed(speed: number): void

  selectTrack(index: number): void

  deselectTrack(index: number): void

  getFillingMode(): SurfaceFillingMode

  setFillingMode(mode: SurfaceFillingMode): void

  isHardwareEncoding(): boolean

  enableHardwareEncoding(): void

  disableHardwareEncoding(): void

  getWindowContext(): WindowContext

  getPlayerContext(): PlayerContext

  onPositionChange(callback: (time: number) => void): void

  onSeekComplete(callback: (time: number) => void): void

  onPrepared(callback: () => void): void

  onPlay(callback: () => void): void

  onPause(callback: () => void): void

  onCompleted(callback: () => void): void

  getContext(): Context

}

abstract class AbstractPlayer implements Player {
  protected context: Context | undefined = undefined
  protected onPositionChangeCallback: (time: number) => void = () => {
  }
  protected onSeekCompleteCallback: (time: number) => void = () => {
  }
  protected onPreparedCallback: () => void = () => {
  }
  protected onPlayCallback: () => void = () => {
  }
  protected onPauseCallback: () => void = () => {
  }
  protected onCompletedCallback: () => void = () => {
  }
  protected cachedMaxDuration: number = 0
  protected longPressSpeeding: boolean = false

  abstract pause(): void

  abstract play(): void

  abstract release(): void

  abstract prepare(abilityContext: Context, context: object, idOrController: XComponentController | string,
    source: VideoSource): void

  abstract currentPosition(): number

  abstract seek(time: number): void

  abstract setSpeed(speed: number): void

  abstract selectTrack(index: number): void

  abstract deselectTrack(index: number): void

  abstract enableHardwareEncoding(): void

  abstract disableHardwareEncoding(): void

  startLongPressSpeeding(): void {
    if (this.longPressSpeeding) {
      return
    }
    this.longPressSpeeding = true
    this.setSpeed(3)
  }

  stopLongPressSpeeding(): void {
    if (!this.longPressSpeeding) {
      return
    }
    this.longPressSpeeding = false
    this.setSpeed(
      AbilityStorage.connect(
        this.context!,
        PlayerContext,
        "player_context",
        () => new PlayerContext()
      )!.playSpeed
    )
  }

  getWindowContext(): WindowContext {
    return Win.get(this.context!)
  }

  getPlayerContext(): PlayerContext {
    return PlayerContext.reach(this.context!)
  }

  isPaused(): boolean {
    let playerContext = AbilityStorage.connect(
      this.context!,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!
    return playerContext.paused
  }

  maxDuration(): number {
    return this.cachedMaxDuration
  }

  protected internalRelease() {
    let playerContext = AbilityStorage.connect(
      this.context!,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!
    playerContext.video = false
    playerContext.videoSource = undefined
    playerContext.player = undefined
    playerContext.currentPosition = 0
    playerContext.maxDuration = 0
    playerContext.playSpeed = 1
    this.cachedMaxDuration = 0
  }

  protected internalPrepare(videoSource: VideoSource) {
    let playerContext = AbilityStorage.connect(
      this.context!,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!
    playerContext.currentPosition = 0
    playerContext.maxDuration = videoSource.metadata().metadata.duration
    this.cachedMaxDuration = videoSource.metadata().metadata.duration
  }

  setFillingMode(mode: SurfaceFillingMode): void {
    if (this.context == undefined) {
      return
    }
    AbilityStorage.connect(
      this.context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!.surfaceFillingMode = mode
  }

  getFillingMode(): SurfaceFillingMode {
    if (this.context == undefined) {
      return SurfaceFillingMode.Fit
    }
    return AbilityStorage.connect(
      this.context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!.surfaceFillingMode
  }

  isHardwareEncoding(): boolean {
    if (this.context == undefined) {
      return false
    }
    return AbilityStorage.connect(
      this.context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!.hardwareEncoding
  }

  onPositionChange(callback: (time: number) => void): void {
    this.onPositionChangeCallback = callback
  }

  onSeekComplete(callback: (time: number) => void): void {
    this.onSeekCompleteCallback = callback
  }

  onPrepared(callback: () => void): void {
    this.onPreparedCallback = callback
  }

  onPlay(callback: () => void): void {
    this.onPlayCallback = callback
  }

  onPause(callback: () => void): void {
    this.onPauseCallback = callback
  }

  onCompleted(callback: () => void): void {
    this.onCompletedCallback = callback
  }

  getContext(): Context {
    return this.context!
  }
}

export class AvPlayer extends AbstractPlayer {
  private avPlayer: media.AVPlayer | undefined = undefined

  private numberToSpeed(speed: number): media.PlaybackSpeed {
    switch (speed) {
      case 0.25:
        return media.PlaybackSpeed.SPEED_FORWARD_0_25_X
      case 0.5:
        return media.PlaybackSpeed.SPEED_FORWARD_0_50_X
      case 0.75:
        return media.PlaybackSpeed.SPEED_FORWARD_0_75_X
      case 1.25:
        return media.PlaybackSpeed.SPEED_FORWARD_1_25_X
      case 1.50:
        return media.PlaybackSpeed.SPEED_FORWARD_1_50_X
      case 1.75:
        return media.PlaybackSpeed.SPEED_FORWARD_1_75_X
      case 2:
        return media.PlaybackSpeed.SPEED_FORWARD_2_00_X
      case 3:
        return media.PlaybackSpeed.SPEED_FORWARD_3_00_X
      case 1:
      default:
        return media.PlaybackSpeed.SPEED_FORWARD_0_75_X
    }
  }

  pause(): void {
    this.avPlayer?.pause()
  }

  play(): void {
    if (this.currentPosition() == this.maxDuration()) {
      this.seek(0)
    }
    this.avPlayer?.play()
  }

  release(): void {
    this.avPlayer?.pause() // 释放前暂停，防止程序出现问题导致视频内容仍在播放（有先例的）
    this.avPlayer?.release()
    this.internalRelease()
    this.context = undefined
    this.avPlayer = undefined
  }

  currentPosition(): number {
    return this.avPlayer?.currentTime ?? 0
  }

  seek(time: number): void {
    this.avPlayer?.seek(time, media.SeekMode.SEEK_CLOSEST)
  }

  setSpeed(speed: number): void {
    if (speed != 3) {
      AbilityStorage.connect(
        this.context!,
        PlayerContext,
        "player_context",
        () => new PlayerContext()
      )!.playSpeed = speed
    }
    if (!this.longPressSpeeding) {
      this.avPlayer?.setSpeed(this.numberToSpeed(speed))
    }
  }

  async prepare(abilityContext: Context, context: object | undefined, idOrController: XComponentController,
    source: VideoSource): Promise<void> {
    if (source.type() != VideoSourceType.Photos) {
      throw Error("av player only supports videos from photos")
    }

    this.context = abilityContext
    source.prepare()

    this.internalPrepare(source)

    let avPlayer = this.avPlayer = await media.createAVPlayer()

    let file = fileIo.openSync(source.url())
    avPlayer.url = `fd://${file.fd}`

    // 下面所有的监听器都不要直接把 callback 传进去，要不然修改了 callback 后 AVPlayer 的回调仍然是原来的
    avPlayer.on('timeUpdate', (time) => {
      this.onPositionChangeCallback(time)
    })
    avPlayer.on('seekDone', (time) => {
      this.onSeekCompleteCallback(time)
    })
    avPlayer.on('stateChange', (state) => {
      if (state == 'paused') {
        this.onPauseCallback()
      } else if (state == "completed") {
        avPlayer.pause()
        this.onCompletedCallback()
      } else if (state == 'playing') {
        this.onPlayCallback()
      } else if (state == 'initialized') {
        avPlayer.surfaceId = idOrController.getXComponentSurfaceId()
        avPlayer.prepare();
      } else if (state == 'prepared') {
        this.onPreparedCallback()
      }
    })
  }

  selectTrack(index: number): void {
    this.avPlayer?.selectTrack(index, media.SwitchMode.SMOOTH)
  }

  deselectTrack(index: number): void {
    this.avPlayer?.deselectTrack(index)
  }

  enableHardwareEncoding(): void {
    hilog.warn(0x1000, 'player', 'av player not support hardware encoding')
  }

  disableHardwareEncoding(): void {
    hilog.warn(0x1000, 'player', 'av player not support hardware encoding')
  }
}

export class IjkPlayer extends AbstractPlayer {
  private ijkPlayer: IjkMediaPlayer | undefined = undefined
  private positionUpdater: number | undefined = undefined
  private cachedCurrentPosition: number = -1

  pause(): void {
    this.ijkPlayer?.pause()
    this.onPauseCallback()
  }

  play(): void {
    if (this.currentPosition() == this.maxDuration()) {
      this.seek(0)
    }
    this.ijkPlayer?.start()
    this.onPlayCallback()
  }

  release(): void {
    this.ijkPlayer?.pause() // 释放前暂停，防止程序出现问题导致视频内容仍在播放（有先例的）
    this.ijkPlayer?.release()
    if (this.positionUpdater != undefined) {
      clearInterval(this.positionUpdater)
    }
    this.internalRelease()
    this.context = undefined
    this.ijkPlayer = undefined
    this.positionUpdater = undefined
  }

  setSpeed(speed: number): void {
    if (speed != 3) {
      AbilityStorage.connect(
        this.context!,
        PlayerContext,
        "player_context",
        () => new PlayerContext()
      )!.playSpeed = speed
    }
    this.ijkPlayer?.setSpeed(`${speed}f`)
  }

  prepare(abilityContext: Context, context: object, idOrController: XComponentController | string,
    source: VideoSource): void {
    if (source.type() == VideoSourceType.Photos) {
      throw Error("ijk player not supports videos from photos")
    }

    this.context = abilityContext
    source.prepare()

    this.internalPrepare(source)

    let ijkPlayer = new IjkMediaPlayer()
    this.ijkPlayer = ijkPlayer

    ijkPlayer.setContext(context, idOrController as string)
    ijkPlayer.native_setup();

    ijkPlayer.setDataSource(new fileUri.FileUri(source.url()).path)
    let headers: Map<string, string> = new Map()
    let sourceHeaders = source.headers()
    if (sourceHeaders != undefined) {
      for (let key of Object.keys(sourceHeaders)) {
        headers.set(key, sourceHeaders[key])
      }
    }
    if (headers != null) {
      ijkPlayer.setDataSourceHeader(headers)
    }

    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "enable-accurate-seek", "1")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max-buffer-size", "102400")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "min-frames", "120")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "start-on-prepared", "1")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "packet-buffering", "0")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "framedrop", "5")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "max_cached_duration", "5000")
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "infbuf", "1")

    // timeout
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "timeout", "10000000");
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "connect_timeout", "10000000");
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "listen_timeout", "10000000");
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "addrinfo_timeout", "10000000");
    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_FORMAT, "dns_cache_timeout", "10000000");

    ijkPlayer.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "soundtouch", "1");

    this.positionUpdater = setInterval(() => {
      let currentPosition = this.ijkPlayer?.getCurrentPosition() || 0
      if (currentPosition == this.cachedCurrentPosition) {
        return
      }
      this.cachedCurrentPosition = currentPosition
      this.onPositionChangeCallback(currentPosition)
    }, 100);
    ijkPlayer.setOnSeekCompleteListener({
      onSeekComplete: () => {
        this.onSeekCompleteCallback(this.ijkPlayer?.getCurrentPosition() || 0)
      }
    })
    ijkPlayer.setOnPreparedListener({
      onPrepared: () => {
        this.onPreparedCallback()
      }
    })
    ijkPlayer.setOnCompletionListener({
      onCompletion: () => {
        ijkPlayer.pause()
        this.onCompletedCallback()
      }
    })

    ijkPlayer.setMessageListener();
    ijkPlayer.prepareAsync();
  }

  currentPosition(): number {
    return this.ijkPlayer?.getCurrentPosition() ?? 0
  }

  seek(time: number): void {
    this.ijkPlayer?.seekTo(time.toString())
  }

  selectTrack(index: number): void {
    this.ijkPlayer?.selectTrack(`${index}`)
  }

  deselectTrack(index: number): void {
    this.ijkPlayer?.deselectTrack(`${index}`)
  }

  enableHardwareEncoding(): void {
    if (this.isHardwareEncoding()) {
      return
    }

    AbilityStorage.connect(
      this.context!,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!.hardwareEncoding = true

    this.ijkPlayer?.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-all-videos", "1");
    this.ijkPlayer?.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-hevc", "1");
  }

  disableHardwareEncoding(): void {
    if (!this.isHardwareEncoding()) {
      return
    }

    AbilityStorage.connect(
      this.context!,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!.hardwareEncoding = false

    this.ijkPlayer?.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-all-videos", "0");
    this.ijkPlayer?.setOption(IjkMediaPlayer.OPT_CATEGORY_PLAYER, "mediacodec-hevc", "0");
  }
}
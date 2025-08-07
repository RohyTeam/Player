import { VideoSource, VideoSourceType } from "./VideoSource";
import { media } from "@kit.MediaKit";
import { SurfaceFillingMode } from "./SurfaceFillingMode";
import { AbilityStorage } from "../storage/AbilityStorage";
import { PlayerContext } from "./PlayerContext";
import { IjkMediaPlayer } from "@ohos/ijkplayer";
import { hilog } from "@kit.PerformanceAnalysisKit";
import { fileIo, fileUri } from "@kit.CoreFileKit";

export interface Player {

  play(): void
  pause(): void
  release(): void
  prepare(abilityContext: Context, context: object | undefined, controller: XComponentController, source: VideoSource): void

  seek(time: number): void

  selectTrack(index: number): void
  deselectTrack(index: number): void

  getFillingMode(): SurfaceFillingMode
  setFillingMode(mode: SurfaceFillingMode): void

  isHardwareEncoding(): boolean
  enableHardwareEncoding(): void
  disableHardwareEncoding(): void

  onPositionChange(callback: (time: number) => void): void
  onSeekComplete(callback: (time: number) => void): void
  onPrepared(callback: () => void): void
  onPlay(callback: () => void): void
  onPause(callback: () => void): void
  onCompleted(callback: () => void): void

}

abstract class AbstractPlayer implements Player {

  protected context: Context | undefined = undefined

  protected onPositionChangeCallback: (time: number) => void = () => {}
  protected onSeekCompleteCallback: (time: number) => void = () => {}
  protected onPreparedCallback: () => void = () => {}
  protected onPlayCallback: () => void = () => {}
  protected onPauseCallback: () => void = () => {}
  protected onCompletedCallback: () => void = () => {}

  abstract pause(): void
  abstract play(): void
  abstract release(): void
  abstract prepare(abilityContext: Context, context: object, idOrController: XComponentController | string, source: VideoSource): void
  abstract seek(time: number): void

  abstract selectTrack(index: number): void
  abstract deselectTrack(index: number): void

  abstract enableHardwareEncoding(): void
  abstract disableHardwareEncoding(): void

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
    playerContext.currentDuration = 0
    playerContext.maxDuration = 0
  }

  protected internalPrepare(videoSource: VideoSource) {
    let playerContext = AbilityStorage.connect(
      this.context!,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!
    playerContext.currentDuration = 0
    playerContext.maxDuration = videoSource.metadata().duration
  }

  setFillingMode(mode: SurfaceFillingMode): void {
    if (this.context == undefined)
      return
    AbilityStorage.connect(
      this.context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!.surfaceFillingMode = mode
  }

  getFillingMode(): SurfaceFillingMode {
    if (this.context == undefined)
      return SurfaceFillingMode.Fit
    return AbilityStorage.connect(
      this.context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!.surfaceFillingMode
  }

  isHardwareEncoding(): boolean {
    if (this.context == undefined)
      return false
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

}

export class AvPlayer extends AbstractPlayer {

  private avPlayer: media.AVPlayer | undefined = undefined

  pause(): void {
    this.avPlayer?.pause()
  }

  play(): void {
    this.avPlayer?.play()
  }

  release(): void {
    this.avPlayer?.pause() // 释放前暂停，防止程序出现问题导致视频内容仍在播放（有先例的）
    this.avPlayer?.release()
    this.context = undefined
    this.avPlayer = undefined
    this.internalRelease()
  }

  seek(time: number): void {
    this.avPlayer?.seek(time, media.SeekMode.SEEK_CLOSEST)
  }

  async prepare(abilityContext: Context, context: object | undefined, idOrController: XComponentController, source: VideoSource): Promise<void> {
    if (source.type() != VideoSourceType.Photos)
      throw Error("av player only supports videos from photos")

    this.context = abilityContext
    source.prepare()

    this.internalPrepare(source)

    let avPlayer = this.avPlayer = await media.createAVPlayer()

    avPlayer.url = source.url()

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

  pause(): void {
    this.ijkPlayer?.pause()
    this.onPauseCallback()
  }

  play(): void {
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

  prepare(abilityContext: Context, context: object, idOrController: XComponentController | string, source: VideoSource): void {
    if (source.type() == VideoSourceType.Photos)
      throw Error("ijk player not supports videos from photos")

    this.context = abilityContext
    source.prepare()

    this.internalPrepare(source)

    let ijkPlayer = new IjkMediaPlayer()
    this.ijkPlayer = ijkPlayer

    ijkPlayer.setContext(context, idOrController as string)
    ijkPlayer.native_setup();

    ijkPlayer.setDataSource(new fileUri.FileUri(source.url()).path)
    let headers = source.headers()
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
      this.onPositionChangeCallback(this.ijkPlayer?.getCurrentPosition() || 0)
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
    if (this.isHardwareEncoding())
      return

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
    if (!this.isHardwareEncoding())
      return

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
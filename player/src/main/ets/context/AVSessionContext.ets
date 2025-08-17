import { ensureContext } from '../utils/AbilityUtils';
import { avSession } from '@kit.AVSessionKit';
import { VideoSource } from '../player/VideoSource';
import { image } from '@kit.ImageKit';
import { PlayerController } from '../player/PlayerController';
import { AbilityStorage } from '../storage/AbilityStorage';
import { PlayerContext } from '../player/PlayerContext';
import { ensurePath } from '../utils/FileUtils';

export class AVSessionContext {
  private static session: avSession.AVSession | undefined = undefined

  public static async startSession(rawContext: UIContext | Context, source: VideoSource,
    playerController: PlayerController) {
    if (AVSessionContext.session) {
      return
    }
    let context = ensureContext(rawContext)
    let session = await avSession.createAVSession(context, 'rohy_player', 'video')
    AVSessionContext.session = session
    let videoMetadata = source.metadata().metadata
    let cover: image.PixelMap | undefined
    if (videoMetadata.cover != null) {
      if (typeof videoMetadata.cover == 'string') {
        cover = image.createImageSource(ensurePath(videoMetadata.cover)).createPixelMapSync()
      } else {
        cover = image.createImageSource(videoMetadata.cover).createPixelMapSync()
      }
    } else {
      cover = undefined
    }
    await session.setAVMetadata({
      assetId: source.identity(),
      title: source.name(),
      mediaImage: cover,
      duration: videoMetadata.duration
    })
    session.setAVPlaybackState({
      state: avSession.PlaybackState.PLAYBACK_STATE_PLAY,
      speed: 1,
      position: {
        elapsedTime: 0,
        updateTime: 0
      },
      duration: videoMetadata.duration,
      videoWidth: videoMetadata.width,
      videoHeight: videoMetadata.height
    })
    session.on('play', () => {
      playerController.play()
      session.setAVPlaybackState({
        state: avSession.PlaybackState.PLAYBACK_STATE_PLAY
      })
    })
    session.on('pause', () => {
      playerController.pause()
      session.setAVPlaybackState({
        state: avSession.PlaybackState.PLAYBACK_STATE_PAUSE
      })
    })
    session.on('stop', () => {
      playerController.release()
      session.setAVPlaybackState({
        state: avSession.PlaybackState.PLAYBACK_STATE_RELEASED
      })
    })
    session.on('seek', (time) => {
      playerController.seek(time)
      session.setAVPlaybackState({
        position: {
          elapsedTime: time,
          updateTime: Date.now()
        }
      })
    })
    session.on('fastForward', (time) => {
      if (!time) {
        return
      }
      playerController.goForward(time * 1000)
      let playerContext = AbilityStorage.connect(
        context,
        PlayerContext,
        "player_context",
        () => new PlayerContext()
      )!
      session.setAVPlaybackState({
        position: {
          elapsedTime: playerContext.currentPosition,
          updateTime: Date.now()
        }
      })
    })
    session.on('rewind', (time) => {
      if (!time) {
        return
      }
      playerController.goBackward(time * 1000)
      let playerContext = AbilityStorage.connect(
        context,
        PlayerContext,
        "player_context",
        () => new PlayerContext()
      )!
      session.setAVPlaybackState({
        position: {
          elapsedTime: playerContext.currentPosition,
          updateTime: Date.now()
        }
      })
    })
    await session.activate()
  }

  public static async updateSession(rawContext: UIContext | Context) {
    if (!AVSessionContext.session) {
      return
    }
    let context = ensureContext(rawContext)
    let session = AVSessionContext.session
    let playerContext = AbilityStorage.connect(
      context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!
    session.setAVPlaybackState({
      state: playerContext.paused ? avSession.PlaybackState.PLAYBACK_STATE_PAUSE :
      avSession.PlaybackState.PLAYBACK_STATE_PLAY,
      speed: playerContext.playSpeed,
      position: {
        elapsedTime: playerContext.currentPosition,
        updateTime: Date.now()
      },
    })
  }

  public static async stopSession() {
    console.error(`[Rohy AVSessionContext] ready to destroy sesstion`)
    if (!AVSessionContext.session) {
      return
    }
    console.error(`[Rohy AVSessionContext] yes there is session to stop`)
    let session = AVSessionContext.session
    session.off('play')
    session.off('pause')
    session.off('stop')
    session.off('seek')
    session.off('fastForward')
    session.off('rewind')
    console.error(`[Rohy AVSessionContext] events unlistened`)
    await session.deactivate()
    console.error(`[Rohy AVSessionContext] session deactivated`)
    await session.destroy()
    console.error(`[Rohy AVSessionContext] session destoryed`)
  }
}
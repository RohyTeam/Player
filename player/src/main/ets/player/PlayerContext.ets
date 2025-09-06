import { AbilityStorage } from '../storage/AbilityStorage';
import { SubtitleInfo } from './subtitle/SubtitleInfo';
import { Player } from './Player';
import { SurfaceFillingMode } from './SurfaceFillingMode';
import { VideoSource } from './VideoSource';
import { AudioInfo } from './audio/AudioInfo';
import { ChapterInfo } from './chapter/ChapterInfo';

@ObservedV2
export class PlayerContext {
  // play info
  @Trace
  video: boolean = false
  @Trace
  videoSource: VideoSource | undefined = undefined
  // player
  @Trace
  player: Player | undefined = undefined
  // player properties
  @Trace
  playSpeed: number = 1
  @Trace
  currentScreenBrightness: number = 1
  @Trace
  currentVolume: number = 1
  // player status
  @Trace
  speedingUp: boolean = false
  @Trace
  movingPosition: boolean = false
  @Trace
  adjustingVolume: boolean = false
  @Trace
  adjustingScreenBrightness: boolean = false
  @Trace
  adjustingProgress: boolean = false
  @Trace
  lastTimeForward: number = 0
  @Trace
  lastTimeBackward: number = 0
  // position status
  @Trace
  paused: boolean = true
  @Trace
  currentPosition: number = 0
  @Trace
  targetPosition: number = 0
  @Trace
  maxDuration: number = 0
  // ui properties
  @Trace
  playerWidthPx: number = 0
  @Trace
  playerHeightPx: number = 0
  @Trace
  playerWidthVp: number = 0
  @Trace
  playerHeightVp: number = 0
  // track infos
  @Trace
  audios: AudioInfo[] = []
  @Trace
  selectedAudio: number = 0
  @Trace
  subtitles: SubtitleInfo[] = []
  @Trace
  selectedSubtitle: number | undefined = undefined
  // chapters
  chapters: ChapterInfo[] = []
  // preferences
  @Trace
  surfaceFillingMode: SurfaceFillingMode = SurfaceFillingMode.Fit
  @Trace
  hardwareEncoding: boolean = false
  subtitlePositionUpdater: (time: number) => void = () => {
  }

  public static reach(context: UIContext | Context): PlayerContext {
    return AbilityStorage.connect(
      context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!
  }
}
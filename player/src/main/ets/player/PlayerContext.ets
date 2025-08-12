import { TrackMetadata } from '../metadata/TrackMetadata';
import { AbilityStorage } from '../storage/AbilityStorage';
import { SubtitleInfo } from '../subtitle/SubtitleInfo';
import { Player } from './Player';
import { SurfaceFillingMode } from './SurfaceFillingMode';
import { VideoSource } from './VideoSource';

@ObservedV2
export class PlayerContext {
  @Trace
  video: boolean = false
  @Trace
  paused: boolean = true
  @Trace
  videoSource: VideoSource | undefined = undefined
  @Trace
  player: Player | undefined = undefined
  @Trace
  playSpeed: number = 1
  @Trace
  currentPosition: number = 0
  @Trace
  maxDuration: number = 0
  @Trace
  playerWidthPx: number = 0
  @Trace
  playerHeightPx: number = 0
  @Trace
  playerWidthVp: number = 0
  @Trace
  playerHeightVp: number = 0
  @Trace
  subtitles: SubtitleInfo[] = []
  @Trace
  selectedSubtitle: number | undefined = undefined
  @Trace
  surfaceFillingMode: SurfaceFillingMode = SurfaceFillingMode.Fit
  @Trace
  hardwareEncoding: boolean = false

  subtitlePositionUpdater: (time: number) => void = () => {}

  public static reach(context: UIContext | Context): PlayerContext {
    return AbilityStorage.connect(
      context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!
  }

}
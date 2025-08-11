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
  surfaceFillingMode: SurfaceFillingMode = SurfaceFillingMode.Fit
  @Trace
  hardwareEncoding: boolean = false
}
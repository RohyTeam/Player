import { SurfaceFillingMode } from "./SurfaceFillingMode";

@ObservedV2
export class PlayerContext {

  @Trace
  surfaceFillingMode: SurfaceFillingMode
  @Trace
  hardwareEncoding: boolean

  public constructor(
    surfaceFillingMode?: SurfaceFillingMode,
    hardwareEncoding?: boolean
  ) {
    this.surfaceFillingMode = surfaceFillingMode ?? SurfaceFillingMode.Fit
    this.hardwareEncoding = hardwareEncoding ?? false
  }

}
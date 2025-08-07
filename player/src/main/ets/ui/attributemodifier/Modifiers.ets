import { VideoMetadata } from "../../metadata/VideoMetadata";
import { SurfaceFillingMode } from "../../player/SurfaceFillingMode";
import { BackgroundBlurModifier } from "./BackgroundBlurModifier";
import { SurfaceFillingModeModifier } from "./SurfaceFillingModeModifier";

export class Modifiers {

  public static backgroundBlur(): BackgroundBlurModifier {
    return new BackgroundBlurModifier()
  }

  public static surfaceFilling(metadata: VideoMetadata, surfaceFillingMode: SurfaceFillingMode): SurfaceFillingModeModifier {
    return new SurfaceFillingModeModifier(metadata, surfaceFillingMode)
  }

}
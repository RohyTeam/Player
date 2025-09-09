import { VideoMetadata } from '../../metadata/VideoMetadata';
import { SurfaceFillingMode } from '../../player/SurfaceFillingMode';
import { BackgroundBlurModifier } from './BackgroundBlurModifier';
import { GridLayoutModifier } from './GridLayoutModifier';
import { SurfaceFillingModeModifier } from './SurfaceFillingModeModifier';

export class Modifiers {
  public static backgroundBlur(): BackgroundBlurModifier {
    return new BackgroundBlurModifier()
  }
  public static optionalBackgroundBlur(enable: boolean): BackgroundBlurModifier {
    return new BackgroundBlurModifier(enable)
  }

  public static surfaceFilling(metadata: VideoMetadata,
    surfaceFillingMode: SurfaceFillingMode): SurfaceFillingModeModifier {
    return new SurfaceFillingModeModifier(metadata, surfaceFillingMode)
  }

  public static gridLayout(context: UIContext): GridLayoutModifier {
    return new GridLayoutModifier(context)
  }
}
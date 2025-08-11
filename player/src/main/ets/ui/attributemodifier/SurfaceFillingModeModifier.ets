import { VideoMetadata } from '../../metadata/VideoMetadata';
import { SurfaceFillingMode } from '../../player/SurfaceFillingMode';
import { CommonModifier } from '@kit.ArkUI';
import { Win } from '../../context/WindowContext';

export class SurfaceFillingModeModifier extends CommonModifier {
  private metadata: VideoMetadata
  private mode: SurfaceFillingMode

  constructor(metadata: VideoMetadata, mode: SurfaceFillingMode) {
    super()
    this.metadata = metadata
    this.mode = mode
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    let windowContext = Win.get(getContext())
    if (this.mode == SurfaceFillingMode.Stretch) {
      instance.width("100%")
        .height("100%")
    } else if (this.mode == SurfaceFillingMode.SixteenToNine) {
      if (windowContext.widthPx / windowContext.heightPx > 16 / 9) {
        instance.aspectRatio(16 / 9)
          .height("100%")
      } else {
        instance.aspectRatio(16 / 9)
          .width("100%")
      }
    } else if (this.mode == SurfaceFillingMode.FourToThree) {
      if (windowContext.widthPx / windowContext.heightPx > 4 / 3) {
        instance.aspectRatio(4 / 3)
          .height("100%")
      } else {
        instance.aspectRatio(4 / 3)
          .width("100%")
      }
    } else {
      let expectedRatio = this.metadata.width / this.metadata.height
      instance.aspectRatio(expectedRatio)
      if (windowContext.widthPx / windowContext.heightPx > expectedRatio) {
        instance.aspectRatio(expectedRatio)
          .height("100%")
      } else {
        instance.aspectRatio(expectedRatio)
          .width("100%")
      }
    }
  }
}
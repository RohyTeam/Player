export enum SurfaceFillingMode {

  Stretch = 0,
  Fit = 1,
  FourToThree = 2,
  SixteenToNine = 3

}

export const SURFACE_FILLING_MODES: SurfaceFillingMode[] = [
  SurfaceFillingMode.Stretch,
  SurfaceFillingMode.Fit,
  SurfaceFillingMode.FourToThree,
  SurfaceFillingMode.SixteenToNine,
]

export const SURFACE_FILLING_MODE_NAMES: ResourceStr[] = [
  $r("app.string.surface_filling_mode_stretch"),
  $r("app.string.surface_filling_mode_fit"),
  $r("app.string.surface_filling_mode_4_to_3"),
  $r("app.string.surface_filling_mode_16_to_9"),
]
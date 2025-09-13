import { preferences } from '@kit.ArkData'
import { Con, ControllerContext } from './ControllerContext'

@ObservedV2
export class PreferenceContext {
  @Trace
  colorMode: ThemeColorMode = ThemeColorMode.SYSTEM
  @Trace
  hardwareDecoding: boolean = false
  @Trace
  screenForwardAndBackward: boolean = true
  @Trace
  uiUpdatePreview: boolean = false
  @Trace
  blurStyle: BlurStyle = BlurStyle.Thin
  @Trace
  blurLevel: number = 0.8
  @Trace
  blurRadius: number = 80
  @Trace
  blurBrightness: number = 1.07
  @Trace
  blurSaturation: number = 1.2
  @Trace
  blurBackgroundColor: boolean = true
  @Trace
  alwaysFold: boolean = false
  @Trace
  topBar: number[] = [0, 1, 2, 3]
  @Trace
  bottomBar: number[] = [4, 5, 6, 7]
  @Trace
  topBarFolded: number[] = []
  @Trace
  bottomBarFolded: number[] = []
  @Trace
  innerRadius: number = 16
  @Trace
  outerRadius: number = 32

  public static load(context: Context) {
    let preference = preferences.getPreferencesSync(context, { name: "general_settings" })
    Pref.colorMode = preference.getSync("color_mode", ThemeColorMode.SYSTEM) as ThemeColorMode
    Pref.hardwareDecoding = preference.getSync("hardware_decoding", false) as boolean
    Pref.screenForwardAndBackward = preference.getSync("screen_forward_and_backward", true) as boolean
    Pref.uiUpdatePreview = preference.getSync("ui_update_preview", false) as boolean
    Pref.blurStyle = numberToBlurStyle(preference.getSync("blur_style", 0) as number)
    Pref.blurLevel = preference.getSync("blur_level", 0.8) as number
    Pref.blurRadius = preference.getSync("blur_radius", 80) as number
    Pref.blurBrightness = preference.getSync("blur_brightness", 1.07) as number
    Pref.blurSaturation = preference.getSync("blur_saturation", 1.2) as number
    Pref.blurBackgroundColor = preference.getSync("blur_background_color", true) as boolean
    Pref.alwaysFold = preference.getSync("always_fold", false) as boolean
    Pref.topBar = preference.getSync("top_bar", [0, 1, 2, 3]) as number[]
    Pref.bottomBar = preference.getSync("bottom_bar", [4, 5, 6, 7]) as number[]
    Pref.topBarFolded = preference.getSync("top_bar_folded", []) as number[]
    Pref.bottomBarFolded = preference.getSync("bottom_bar_folded", []) as number[]

    ControllerContext.init()
  }

  public static save(context: Context) {
    let preference = preferences.getPreferencesSync(context, { name: "general_settings" })
    ControllerContext.save()
    preference.putSync("color_mode", Pref.colorMode)
    preference.putSync("hardware_decoding", Pref.hardwareDecoding)
    preference.putSync("screen_forward_and_backward", Pref.screenForwardAndBackward)
    preference.putSync("ui_update_preview", Pref.uiUpdatePreview)
    preference.putSync("blur_style", blurStyleToNumber(Pref.blurStyle))
    preference.putSync("blur_level", Pref.blurLevel)
    preference.putSync("blur_radius", Pref.blurRadius)
    preference.putSync("blur_brightness", Pref.blurBrightness)
    preference.putSync("blur_saturation", Pref.blurSaturation)
    preference.putSync("blur_background_color", Pref.blurBackgroundColor)
    preference.putSync("always_fold", Pref.alwaysFold)
    preference.putSync("top_bar", Pref.topBar)
    preference.putSync("bottom_bar", Pref.bottomBar)
    preference.putSync("top_bar_folded", Pref.topBarFolded)
    preference.putSync("bottom_bar_folded", Pref.bottomBarFolded)
    preference.putSync("inner_radius", Pref.innerRadius)
    preference.putSync("outer_radius", Pref.outerRadius)
    preference.flushSync()
  }
}

export function numberToBlurStyle(value: number): BlurStyle {
  if (value == 0) {
    return BlurStyle.Thin
  } else if (value == 2) {
    return BlurStyle.Thick
  } else {
    return BlurStyle.Regular
  }
}

export function blurStyleToNumber(value: BlurStyle): number {
  if (value == BlurStyle.Thin) {
    return 0
  } else if (value == BlurStyle.Thick) {
    return 2
  } else {
    return 1
  }
}

export let Pref: PreferenceContext = new PreferenceContext()
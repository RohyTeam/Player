import { preferences } from '@kit.ArkData'

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
    Pref.innerRadius = preference.getSync("inner_radius", 16) as number
    Pref.outerRadius = preference.getSync("outer_radius", 32) as number
  }

  public static save(context: Context) {
    let preference = preferences.getPreferencesSync(context, { name: "general_settings" })
    preference.putSync("color_mode", Pref.colorMode)
    preference.putSync("hardware_decoding", Pref.hardwareDecoding)
    preference.putSync("screen_forward_and_backward", Pref.screenForwardAndBackward)
    preference.putSync("ui_update_preview", Pref.uiUpdatePreview)
    preference.putSync("blur_style", blurStyleToNumber(Pref.blurStyle))
    preference.putSync("blur_level", Pref.blurLevel)
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
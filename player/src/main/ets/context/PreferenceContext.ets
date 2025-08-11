import { preferences } from '@kit.ArkData'
import { AppStorageV2 } from '@kit.ArkUI'

@ObservedV2
export class PreferenceContext {
  @Trace
  colorMode: ThemeColorMode = ThemeColorMode.SYSTEM

  public static load(context: Context) {
    let preferenceContext = AppStorageV2.connect(PreferenceContext, "preferences", () => new PreferenceContext())!
    let preference = preferences.getPreferencesSync(context, { name: "general_settings" })
    preferenceContext.colorMode = preference.getSync("color_mode", ThemeColorMode.SYSTEM) as ThemeColorMode
  }

  public static save(context: Context) {
    let preferenceContext = AppStorageV2.connect(PreferenceContext, "preferences", () => new PreferenceContext())!
    let preference = preferences.getPreferencesSync(context, { name: "general_settings" })
    preference.putSync("color_mode", preferenceContext.colorMode)
  }
}
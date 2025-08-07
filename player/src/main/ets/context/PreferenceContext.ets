import { preferences } from "@kit.ArkData"
import { common } from "@kit.AbilityKit"
import { randomString } from "../utils/StringUtils"

@ObservedV2
export class PreferenceContext {

  @Trace
  colorMode: ThemeColorMode = ThemeColorMode.SYSTEM

  private id: string = randomString(16)

  public static load(context: Context) {
    let preference = preferences.getPreferencesSync(context, { name: "general_settings" })
    Pref.colorMode = preference.getSync("color_mode", ThemeColorMode.SYSTEM) as ThemeColorMode
  }

  public static save(context: Context) {
    let preference = preferences.getPreferencesSync(context, { name: "general_settings" })
    preference.putSync("color_mode", Pref.colorMode)
  }

}

export const Pref: PreferenceContext = new PreferenceContext()
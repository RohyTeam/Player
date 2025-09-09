import { Pref } from '../../context/PreferenceContext';

export class BackgroundBlurModifier implements AttributeModifier<CommonAttribute> {

  private enable: boolean

  constructor(enable: boolean = true) {
    this.enable = enable
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    if (this.enable) {
      instance.backgroundColor($r("app.color.rohy_background_opacity_50"))
        .backgroundBlurStyle(
          Pref.blurStyle,
          {
            policy: BlurStyleActivePolicy.ALWAYS_ACTIVE,
            scale: Pref.blurLevel,
          }
        )
    }
  }
}
import { Pref } from '../../context/PreferenceContext';

export class BackgroundBlurModifier implements AttributeModifier<CommonAttribute> {
  applyNormalAttribute(instance: CommonAttribute): void {
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
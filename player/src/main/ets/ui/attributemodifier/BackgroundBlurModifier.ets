import { Pref } from '../../context/PreferenceContext';

export class BackgroundBlurModifier implements AttributeModifier<CommonAttribute> {

  private enable: boolean

  constructor(enable: boolean = true) {
    this.enable = enable
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    if (this.enable) {
      /*instance.backgroundColor($r("app.color.rohy_background_opacity_50"))
        .backgroundBlurStyle(
          Pref.blurStyle,
          {
            policy: BlurStyleActivePolicy.ALWAYS_ACTIVE,
            scale: Pref.blurLevel,
          }
        )*/
      // todo: 后续将修改背景模糊的实现方式
      instance.backgroundEffect({
        radius: Pref.blurRadius,
        brightness: Pref.blurBrightness,
        saturation: Pref.blurSaturation,
        policy: BlurStyleActivePolicy.ALWAYS_ACTIVE,
        color: Pref.blurBackgroundColor ? $r('app.color.rohy_background_opacity_50') : undefined
      })
    }
  }
}
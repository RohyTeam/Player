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
      // todo: 后续将修改背景模糊的实现方式
      /*.backgroundEffect({
        radius: 80,
        brightness: 1.07,
        saturation: 1.2
      })*/
    }
  }
}
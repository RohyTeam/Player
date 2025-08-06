export class BackgroundBlurModifier implements AttributeModifier<CommonAttribute> {

  applyNormalAttribute(instance: CommonAttribute): void {
    instance.backgroundColor($r("app.color.rohy_background_opacity_50"))
      .backgroundBlurStyle(
        BlurStyle.Thin,
        {
          policy: BlurStyleActivePolicy.FOLLOWS_WINDOW_ACTIVE_STATE,
          scale: 0.7
        }
      )
  }

}
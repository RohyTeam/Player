export class BackgroundBlurModifier implements AttributeModifier<CommonAttribute> {
  applyNormalAttribute(instance: CommonAttribute): void {
    instance.backgroundColor($r("app.color.rohy_background_opacity_50"))
      .backgroundBlurStyle(
        BlurStyle.Thin,
        {
          policy: BlurStyleActivePolicy.ALWAYS_ACTIVE,
          scale: 0.8,
        }
      )
  }
}
import { WrappedText } from "../../component/wrapper/WrappedText";

export class WrappedTextModifier implements AttributeModifier<TextAttribute> {

  private text: WrappedText

  constructor(wrappedText: WrappedText) {
    this.text = wrappedText
  }

  applyNormalAttribute(instance: TextAttribute): void {
    if (this.text.font !== undefined) {
      instance.font(this.text.font)
    }
    if (this.text.fontColor !== undefined) {
      instance.fontColor(this.text.fontColor)
    }
    if (this.text.fontSize !== undefined) {
      instance.fontSize(this.text.fontSize)
    }
    if (this.text.minFontSize !== undefined) {
      instance.minFontSize(this.text.minFontSize)
    }
    if (this.text.maxFontSize !== undefined) {
      instance.maxFontSize(this.text.maxFontSize)
    }
    if (this.text.minFontScale !== undefined) {
      instance.minFontScale(this.text.minFontScale)
    }
    if (this.text.maxFontScale !== undefined) {
      instance.maxFontScale(this.text.maxFontScale)
    }
    if (this.text.fontStyle !== undefined) {
      instance.fontStyle(this.text.fontStyle)
    }
    if (this.text.fontWeight !== undefined) {
      instance.fontWeight(this.text.fontWeight)
    }
    if (this.text.lineSpacing !== undefined) {
      instance.lineSpacing(this.text.lineSpacing)
    }
    if (this.text.textAlign !== undefined) {
      instance.textAlign(this.text.textAlign)
    }
    if (this.text.lineHeight !== undefined) {
      instance.lineHeight(this.text.lineHeight)
    }
    if (this.text.textOverflow !== undefined) {
      instance.textOverflow({ overflow: this.text.textOverflow })
    }
    if (this.text.fontFamily !== undefined) {
      instance.fontFamily(this.text.fontFamily)
    }
    if (this.text.maxLines !== undefined) {
      instance.maxLines(this.text.maxLines)
    }
    if (this.text.decoration !== undefined) {
      instance.decoration(this.text.decoration)
    }
    if (this.text.letterSpacing !== undefined) {
      instance.letterSpacing(this.text.letterSpacing)
    }
    if (this.text.textCase !== undefined) {
      instance.textCase(this.text.textCase)
    }
    if (this.text.baselineOffset !== undefined) {
      instance.baselineOffset(this.text.baselineOffset)
    }
    if (this.text.copyOption !== undefined) {
      instance.copyOption(this.text.copyOption)
    }
    if (this.text.draggable !== undefined) {
      instance.draggable(this.text.draggable)
    }
    if (this.text.textShadow !== undefined) {
      instance.textShadow(this.text.textShadow)
    }
    if (this.text.heightAdaptivePolicy !== undefined) {
      instance.heightAdaptivePolicy(this.text.heightAdaptivePolicy)
    }
    if (this.text.textIndent !== undefined) {
      instance.textIndent(this.text.textIndent)
    }
    if (this.text.wordBreak !== undefined) {
      instance.wordBreak(this.text.wordBreak)
    }
    if (this.text.lineBreakStrategy !== undefined) {
      instance.lineBreakStrategy(this.text.lineBreakStrategy)
    }
    if (this.text.onCopy !== undefined) {
      instance.onCopy(this.text.onCopy)
    }
    if (this.text.selection !== undefined) {
      instance.selection(this.text.selection.selectionStart, this.text.selection.selectionEnd)
    }
    if (this.text.ellipsisMode !== undefined) {
      instance.ellipsisMode(this.text.ellipsisMode)
    }
    if (this.text.enableDataDetector !== undefined) {
      instance.enableDataDetector(this.text.enableDataDetector)
    }
    if (this.text.dataDetectorConfig !== undefined) {
      instance.dataDetectorConfig(this.text.dataDetectorConfig)
    }
    if (this.text.fontFeature !== undefined) {
      instance.fontFeature(this.text.fontFeature)
    }
    if (this.text.privacySensitive !== undefined) {
      instance.privacySensitive(this.text.privacySensitive)
    }
    if (this.text.textSelectable !== undefined) {
      instance.textSelectable(this.text.textSelectable)
    }
    if (this.text.editMenuOptions !== undefined) {
      instance.editMenuOptions(this.text.editMenuOptions)
    }
    if (this.text.halfLeading !== undefined) {
      instance.halfLeading(this.text.halfLeading)
    }
    if (this.text.enableHapticFeedback !== undefined) {
      instance.enableHapticFeedback(this.text.enableHapticFeedback)
    }
  }

}
import { WrappedComponent } from "./WrappedComponent"

export interface WrappedTextSelection {
  selectionStart: number
  selectionEnd: number
}

export interface WrappedText extends WrappedComponent {

  text: ResourceStr

  font?: Font
  fontColor?: ResourceColor
  fontSize?: string | number | Resource
  minFontSize?: string | number | Resource
  maxFontSize?: string | number | Resource
  minFontScale?: number | Resource
  maxFontScale?: number | Resource
  fontStyle?: FontStyle
  fontWeight?: string | number | FontWeight
  lineSpacing?: LengthMetrics
  textAlign?: TextAlign
  lineHeight?: string | number | Resource
  textOverflow?: TextOverflow
  fontFamily?: string | Resource
  maxLines?: number
  decoration?: DecorationStyleInterface
  letterSpacing?: string | number
  textCase?: TextCase
  baselineOffset?: string | number
  copyOption?: CopyOptions
  draggable?: boolean
  textShadow?: ShadowOptions | ShadowOptions[]
  heightAdaptivePolicy?: TextHeightAdaptivePolicy
  textIndent?: Length
  wordBreak?: WordBreak
  lineBreakStrategy?: LineBreakStrategy
  onCopy?: (value: string) => void
  selection?: WrappedTextSelection
  ellipsisMode?: EllipsisMode
  enableDataDetector?: boolean
  dataDetectorConfig?: TextDataDetectorConfig
  fontFeature?: string
  privacySensitive?: boolean
  textSelectable?: TextSelectableMode
  editMenuOptions?: EditMenuOptions
  halfLeading?: boolean
  enableHapticFeedback?: boolean

}
import { lang } from '@kit.ArkTS'

export interface PgsSubtitleRange extends lang.ISendable {

  index: number
  start: number
  end: number

}
import { DateUtil } from '@pura/harmony-utils'
import { SystemBasicInfo } from '../../../sendable/SystemBasicInfo'

@ComponentV2
export struct TimeInfo {

  @Param
  @Require
  systemBasicInfo: SystemBasicInfo

  build() {
    Text(`${DateUtil.getFormatDateStr(this.systemBasicInfo.time, 'HH:mm')}`)
      .fontColor($r('app.color.font_primary'))
  }

}
import { BatteryInfo } from './info/BatteryInfo'
import { TimeInfo } from './info/TimeInfo'
import { taskpool } from '@kit.ArkTS'
import { SystemBasicInfo } from '../../sendable/SystemBasicInfo'
import { batteryInfo, systemDateTime } from '@kit.BasicServicesKit'
import { UIUtils } from '@kit.ArkUI'
import { BlueToothBatteryInfo } from './info/BlueToothBatteryInfo'


@Concurrent
function updateInfo(): SystemBasicInfo {
  console.error(`updating system basic info, battery: ${batteryInfo.batterySOC}, time: ${systemDateTime.getTime()}`)
  return new SystemBasicInfo()
}

@ComponentV2
export struct StatusBar {
  @Param
  @Require
  statusBarBatteryPercent: boolean = false;
  @Local
  private systemBasicInfo: SystemBasicInfo = UIUtils.makeObserved(new SystemBasicInfo())
  private task: taskpool.Task = new taskpool.Task(updateInfo)

  updateSystemInfo() {
    // FIXME: this method could be unsafe
    let task = new taskpool.Task(updateInfo)
    this.task = task
    taskpool.executeDelayed(5000, task, taskpool.Priority.MEDIUM)
      .then((result) => {
        this.systemBasicInfo = UIUtils.makeObserved(result as SystemBasicInfo);
        this.updateSystemInfo()
      })
  }

  aboutToAppear(): void {
    this.updateSystemInfo()
  }

  aboutToDisappear(): void {
    taskpool.cancel(this.task)
  }

  build() {
    Row() {
      TimeInfo({
        systemBasicInfo: this.systemBasicInfo
      })
      Blank()
        .layoutWeight(1)
      if (this.systemBasicInfo.bluetoothBattery != undefined) {
        BlueToothBatteryInfo({
          systemBasicInfo: this.systemBasicInfo
        })
        Blank()
          .width(8)
      }
      BatteryInfo({
        systemBasicInfo: this.systemBasicInfo
      })
      if (this.statusBarBatteryPercent) {
        Blank()
          .width(4)
        Text(`${this.systemBasicInfo.battery}%`)
          .fontSize(16)
          .fontColor($r('app.color.font_primary'))
      }
    }
    .alignItems(VerticalAlign.Center)
    .width("100%")
  }
}
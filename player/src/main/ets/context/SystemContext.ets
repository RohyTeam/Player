import { taskpool } from "@kit.ArkTS"
import { batteryInfo, deviceInfo } from "@kit.BasicServicesKit"


interface SystemInfo {

  battery: number
  time: number
  charging: boolean

}

@Concurrent
function updateSystemInfo(): SystemInfo {
  return {
    time: Date.now(),
    battery: batteryInfo.batterySOC,
    charging: batteryInfo.chargingStatus == batteryInfo.BatteryChargeState.ENABLE
  }
}

@ObservedV2
export class SystemContext {

  @Trace
  time: number = 0
  @Trace
  battery: number = 0
  @Trace
  charging: boolean = false

  public isPC(): boolean {
    return deviceInfo.deviceType == "2in1" || deviceInfo.deviceType == "tablet" // todo: remove tablet after debug
  }

  private static started: boolean = false
  private static task: taskpool.Task = new taskpool.Task(updateSystemInfo)

  public static start() {
    if (SystemContext.started)
      return
    SystemContext.updateSystemContext()
  }

  public static stop() {
    if (!SystemContext.started)
      return
    taskpool.cancel(SystemContext.task)
  }

  private static updateSystemContext() {
    taskpool.executeDelayed(50, SystemContext.task, taskpool.Priority.HIGH)
      .then((result) => {
        let info = result as SystemInfo
        Sys.time = info.time
        Sys.battery = info.battery
        Sys.charging = info.charging
        SystemContext.updateSystemContext()
      })

  }

}

export const Sys: SystemContext = new SystemContext()
import { taskpool } from '@kit.ArkTS'
import { batteryInfo, deviceInfo } from '@kit.BasicServicesKit'
import { audio } from '@kit.AudioKit'

interface SystemInfo {

  battery: number
  time: number
  charging: boolean
  currentVolume: number
  maxVolume: number
  minVolume: number

}

@Concurrent
async function updateSystemInfo() {
  let volumeGroupManager =
    await audio.getAudioManager().getVolumeManager().getVolumeGroupManager(audio.DEFAULT_VOLUME_GROUP_ID)
  let systemInfo: SystemInfo = {
    time: Date.now(),
    battery: batteryInfo.batterySOC,
    charging: batteryInfo.chargingStatus == batteryInfo.BatteryChargeState.ENABLE,
    currentVolume: volumeGroupManager.getVolumeSync(audio.AudioVolumeType.MEDIA),
    maxVolume: volumeGroupManager.getMaxVolumeSync(audio.AudioVolumeType.MEDIA),
    minVolume: volumeGroupManager.getMinVolumeSync(audio.AudioVolumeType.MEDIA)
  }
  taskpool.Task.sendData(systemInfo)
}

function buildTask(): taskpool.Task {
  let task = new taskpool.Task(updateSystemInfo)
  task.onReceiveData((info: SystemInfo) => {
    console.error(`updated system time: ${Sys.time}`)
    Sys.time = info.time
    Sys.battery = info.battery
    Sys.charging = info.charging
    Sys.currentVolume = info.currentVolume
    Sys.maxVolume = info.maxVolume
    Sys.minVolume = info.minVolume
  })
  task.onExecutionFailed((err: Error) => {
    // 这里可以处理一下运行中出现的错误，但获取系统信息一般不会有问题
    console.error(`error when fetching system info, message: ${err.message}`)
  })
  return task
}

@ObservedV2
export class SystemContext {
  @Trace
  time: number = 0
  @Trace
  battery: number = 0
  @Trace
  charging: boolean = false
  @Trace
  currentVolume: number = 0
  @Trace
  maxVolume: number = 0
  @Trace
  minVolume: number = 0
  private static started: boolean = false
  private static task: taskpool.Task = buildTask()

  public static start() {
    if (SystemContext.started) {
      return
    }
    taskpool.executePeriodically(200, SystemContext.task, taskpool.Priority.HIGH)
  }

  public static stop() {
    if (!SystemContext.started) {
      return
    }
    taskpool.cancel(SystemContext.task)
  }

  public isPC(): boolean {
    return deviceInfo.deviceType == "2in1" // || deviceInfo.deviceType == "tablet" // todo: remove tablet after debug
  }

  public isTablet(): boolean {
    return deviceInfo.deviceType == "tablet"
  }

  public isPhone(): boolean {
    return deviceInfo.deviceType == "phone"
  }
}

export const Sys: SystemContext = new SystemContext()
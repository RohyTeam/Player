import { batteryInfo, systemDateTime } from '@kit.BasicServicesKit'

@Sendable
export class SystemBasicInfo {
  battery: number
  bluetoothBattery: number | undefined = undefined
  time: number
  isCharging: boolean

  constructor() {
    this.battery = batteryInfo.batterySOC
    this.time = systemDateTime.getTime()
    this.isCharging = batteryInfo.chargingStatus == batteryInfo.BatteryChargeState.ENABLE
    /*
        for (let device of connection.getPairedDevices()) {
          let deviceClass = connection.getRemoteDeviceClass(device)
          if (deviceClass.majorClass == constant.MajorClass.MAJOR_AUDIO_VIDEO) {
            connection.getRemoteDeviceBatteryInfo(device)
              .then((battery) => {
                this.bluetoothBattery = battery.batteryLevel
              })
            break
          }
        }*/
  }
}
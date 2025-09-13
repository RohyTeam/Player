import { AbilityStage, Want } from '@kit.AbilityKit'
import { PreferenceContext } from '../../context/PreferenceContext'
import { Sys, SystemContext } from '../../context/SystemContext'
import { DB } from '../../database/DatabaseManager'
import { randomString } from '../../utils/StringUtils'
import { JSON, taskpool } from '@kit.ArkTS'
import { superContext } from '../../utils/AbilityUtils'
import { fileIo } from '@kit.CoreFileKit'
import { parseVtt } from '../../lib/subtitle/vtt/VttParser'
import { hiAppEvent } from '@kit.PerformanceAnalysisKit'

@Concurrent
function periodJob(): void {
  taskpool.Task.sendData(undefined)
}

export default class PlayerAbilityStage extends AbilityStage {
  private static superContext: Context | undefined = undefined
  private static task: taskpool.Task = new taskpool.Task(periodJob)

  async onCreate(): Promise<void> {
    PlayerAbilityStage.superContext = this.context
    await DB.init(this.context)
    PreferenceContext.load(this.context)
    SystemContext.start()

    PlayerAbilityStage.task.onReceiveData(() => {
      PreferenceContext.save(this.context)
    })
    taskpool.executePeriodically(10 * 60 * 1000, PlayerAbilityStage.task, taskpool.Priority.LOW)

    // 软件崩溃后不会清空 temp 文件夹，手动清空
    if (fileIo.accessSync(this.context.tempDir, fileIo.AccessModeType.EXIST)) {
      fileIo.rmdirSync(this.context.tempDir)
    }

    hiAppEvent.addWatcher({
      name: 'RohyPlayerWatcher',
      appEventFilters: [{
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_CRASH, hiAppEvent.event.APP_FREEZE],
      }],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        if (appEventGroups.length <= 0)
          return

        // todo: export fault log to give it to user
      }
    })
  }

  onDestroy(): void {
    taskpool.cancel(PlayerAbilityStage.task)
    PreferenceContext.save(this.context)
    SystemContext.stop()
  }

  onAcceptWant(want: Want): string {
    if (Sys.isPC()) {
      return `RohyPlayer_${randomString(16)}`
    }
    return 'RohyPlayer'
  }

  public static getContext(): Context {
    return PlayerAbilityStage.superContext!!
  }
}
import { AbilityStage, Want } from '@kit.AbilityKit'
import { Pref, PreferenceContext } from '../../context/PreferenceContext'
import { Sys, SystemContext } from '../../context/SystemContext'
import { DB } from '../../database/DatabaseManager'
import { randomString } from '../../utils/StringUtils'
import { taskpool } from '@kit.ArkTS'
import { superContext } from '../../utils/AbilityUtils'
import { setColorMode } from '../../utils/ConfigurationUtils'

@Concurrent
function periodJob(): void {
  PreferenceContext.save(superContext())
}

export default class PlayerAbilityStage extends AbilityStage {
  private static superContext: Context | undefined = undefined
  private static task: taskpool.Task = new taskpool.Task(periodJob)

  private static doPeriodJob() {
    // 10 分钟执行一次
    taskpool.executeDelayed(10 * 60 * 1000, PlayerAbilityStage.task, taskpool.Priority.LOW)
      .then((result) => {
        PlayerAbilityStage.doPeriodJob()
      })
  }

  async onCreate(): Promise<void> {
    PlayerAbilityStage.superContext = this.context
    await DB.init(this.context)
    PreferenceContext.load(this.context)
    SystemContext.start()
    PlayerAbilityStage.doPeriodJob()
  }

  onDestroy(): void {
    PreferenceContext.save(this.context)
    SystemContext.stop()
    taskpool.cancel(PlayerAbilityStage.task)
  }

  onAcceptWant(want: Want): string {
    if (want.abilityName == "SettingsAbility") {
      return 'RohyPlayer_Settings'
    }
    if (Sys.isPC()) {
      return `RohyPlayer_${randomString(16)}`
    }
    return 'RohyPlayer'
  }

  public static getContext(): Context {
    return PlayerAbilityStage.superContext!!
  }
}
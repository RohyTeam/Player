import { AbilityStage, Want } from '@kit.AbilityKit'
import { PreferenceContext } from '../../context/PreferenceContext'
import { Sys, SystemContext } from '../../context/SystemContext'
import { DB } from '../../database/DatabaseManager'
import { randomString } from '../../utils/StringUtils'
import { taskpool } from '@kit.ArkTS'
import { superContext } from '../../utils/AbilityUtils'

@Concurrent
function periodJob(): void {
  PreferenceContext.save(superContext())
}

export default class PlayerAbilityStage extends AbilityStage {
  private static superContext: Context | undefined = undefined
  private static task: taskpool.Task = new taskpool.Task(periodJob)

  async onCreate(): Promise<void> {
    PlayerAbilityStage.superContext = this.context
    await DB.init(this.context)
    PreferenceContext.load(this.context)
    SystemContext.start()
    taskpool.executePeriodically(10 * 60 * 1000, PlayerAbilityStage.task, taskpool.Priority.LOW)
  }

  onDestroy(): void {
    PreferenceContext.save(this.context)
    SystemContext.stop()
    taskpool.cancel(PlayerAbilityStage.task)
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
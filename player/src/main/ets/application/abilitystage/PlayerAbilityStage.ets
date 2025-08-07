import { AbilityStage, Want } from '@kit.AbilityKit'
import { PreferenceContext } from '../../context/PreferenceContext'
import { Sys, SystemContext } from '../../context/SystemContext'
import { DB } from '../../database/DatabaseManager'
import { randomString } from '../../utils/StringUtils'

export default class PlayerAbilityStage extends AbilityStage {

  async onCreate(): Promise<void> {
    await DB.init(this.context)
    PreferenceContext.load(this.context)
    SystemContext.start()
  }

  onDestroy(): void {
    PreferenceContext.save(this.context)
    SystemContext.stop()
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

}
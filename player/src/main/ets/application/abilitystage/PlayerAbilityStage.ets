import { AbilityStage, Want } from '@kit.AbilityKit'
import { Sys } from '../../context/SystemContext'
import { DB } from '../../database/DatabaseManager'
import { randomString } from '../../utils/StringUtils'

export default class PlayerAbilityStage extends AbilityStage {

  async onCreate(): Promise<void> {
    await DB.init(this.context)
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
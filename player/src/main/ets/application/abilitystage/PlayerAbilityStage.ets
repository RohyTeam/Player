import { AbilityStage, Want } from '@kit.AbilityKit'
import { Sys } from '../../context/SystemContext'
import { randomString } from '../../utils/StringUtils'

export default class PlayerAbilityStage extends AbilityStage {

  onAcceptWant(want: Want): string {
    if (want.abilityName == "SettingsAbility")
      return 'RohyPlayer_Settings'
    if (Sys.isPC()) {
      return `RohyPlayer_${randomString(16)}`
    }
    return 'RohyPlayer'
  }

}
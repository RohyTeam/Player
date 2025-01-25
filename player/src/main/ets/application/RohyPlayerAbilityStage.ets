import { AbilityStage, Want } from '@kit.AbilityKit'

export default class RohyPlayerAbilityStage extends AbilityStage {
  onAcceptWant(want: Want) {
    if (want && want.abilityName == "VideoAbility") {
      if (want.parameters) {
        return `VideoAbility${want.parameters.hash}`
      } else if (want.uri) {
        return `VideoAbility${want.uri}`
      }
    }
    return ''
  }
}
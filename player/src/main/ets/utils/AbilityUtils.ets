import { UIContext, window } from "@kit.ArkUI";
import { common, Context } from "@kit.AbilityKit";
import PlayerAbility from "../application/ability/PlayerAbility";

export function abilityKey(context: UIContext | Context): string {
  let identifier = ability(context).getIdentifier()
  console.error(`fetching ability identifier: ${identifier}`)
  return identifier
}

export function abilityWindow(context: UIContext | Context): window.Window {
  return ability(context).context.windowStage.getMainWindowSync()
}

export function ability(context: UIContext | Context): PlayerAbility {
  let realContext: Context
  if (context instanceof UIContext) {
    realContext = context.getHostContext()!
  } else {
    realContext = context
  }
  console.error(`fetching ability for: ${realContext}`)
  return PlayerAbility.getAbility((realContext as common.UIAbilityContext))
}
import { common, Want } from "@kit.AbilityKit";

export function openVideo(context: common.UIAbilityContext, uri: string, title: string, hash: string) {
  let want: Want = {
    bundleName: 'org.rohy.player',
    abilityName: 'VideoAbility',
    parameters: {
      'url': uri,
      'title': title,
      'hash': hash
    }
  }
  context.startAbility(want)
}
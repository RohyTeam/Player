import { common, Want } from '@kit.AbilityKit';
import { Headers } from '../entity/Headers';
import { JSON } from '@kit.ArkTS';

export function openVideo(context: common.UIAbilityContext, uri: string, title: string, hash: string,
  headers?: Headers) {
  let want: Want
  if (headers == undefined) {
    want = {
      bundleName: 'org.rohy.player',
      abilityName: 'VideoAbility',
      parameters: {
        'url': uri,
        'title': title,
        'hash': hash
      }
    }
  } else {
    want = {
      bundleName: 'org.rohy.player',
      abilityName: 'VideoAbility',
      parameters: {
        'url': uri,
        'title': title,
        'hash': hash,
        'headers': JSON.stringify(headers)
      }
    }
  }
  context.startAbility(want)
}
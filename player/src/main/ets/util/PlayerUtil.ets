import { common, Want } from '@kit.AbilityKit';
import { Headers } from '../entity/Headers';
import { JSON } from '@kit.ArkTS';

export interface PlayerMetadata {

  length: number
  width: number
  height: number

}

export function openVideo(context: common.UIAbilityContext, uri: string, title: string, hash: string,
  metadata: PlayerMetadata,
  headers?: Headers) {
  console.error(`opening video ${uri}`)
  let want: Want
  if (headers == undefined) {
    want = {
      bundleName: 'org.rohy.player',
      abilityName: 'VideoAbility',
      parameters: {
        'url': uri,
        'title': title,
        'hash': hash,
        'metadata': JSON.stringify(metadata)
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
        'metadata': JSON.stringify(metadata),
        'headers': JSON.stringify(headers)
      }
    }
  }
  context.startAbility(want)
}
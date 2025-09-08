import { UIContext, window } from '@kit.ArkUI';
import { common, wantConstant, Context, Want } from '@kit.AbilityKit';
import PlayerAbility from '../application/ability/PlayerAbility';
import PlayerAbilityStage from '../application/abilitystage/PlayerAbilityStage';
import { BusinessError } from '@kit.BasicServicesKit';

export function superContext(): Context {
  return PlayerAbilityStage.getContext()
}

export function abilityKey(context: UIContext | Context): string {
  let identifier = ability(context).getIdentifier()
  return identifier
}

export function abilityWindow(context: UIContext | Context): window.Window {
  return ability(context).context.windowStage.getMainWindowSync()
}

export function ensureContext(context: UIContext | Context): Context {
  if (context instanceof UIContext) {
    return context.getHostContext()!
  } else {
    return context
  }
}

export function ensureUIAbilityContext(context: UIContext | Context): common.UIAbilityContext {
  if (context instanceof UIContext) {
    return context.getHostContext()! as common.UIAbilityContext
  } else {
    return context as common.UIAbilityContext
  }
}

export function ability(context: UIContext | Context): PlayerAbility {
  let realContext: Context
  if (context instanceof UIContext) {
    realContext = context.getHostContext()!
  } else {
    realContext = context
  }
  return PlayerAbility.getAbility((realContext as common.UIAbilityContext))
}

export function openEmail(rawContext: UIContext | Context, email: string, subject: string) {
  let context = ensureUIAbilityContext(rawContext)
  let wantParam: Record<string, Object> = {
    'sceneType': 1,
    'email': [encodeURI(email)],
    'subject': encodeURI(subject),
    'ability.want.params.uriPermissionFlag': wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
  };
  let abilityStartCallback: common.AbilityStartCallback = {
    onError: (code: number, name: string, message: string) => {
      console.log(`onError code ${code} name: ${name} message: ${message}`);
    },
    onResult: (result) => {
      console.log(`onResult result: ${JSON.stringify(result)}`);
    }
  }

  context.startAbilityByType("mail", wantParam, abilityStartCallback,
    (err) => {
      if (err) {
        console.error(`startAbilityByType fail, err: ${JSON.stringify(err)}`);
      } else {
        console.log(`success`);
      }
    });
}

export function openUrl(rawContext: UIContext | Context, url: string) {
  let context = ensureUIAbilityContext(rawContext)
  let want: Want = {
    action: 'ohos.want.action.viewData',
    entities: ['entity.system.browsable'],
    uri: url,
    parameters: {
      'ohos.ability.params.showDefaultPicker': true
    }
  };
  context.startAbility(want)
    .then(() => {
      console.error('Start browsableAbility successfully.');
    })
    .catch((err: BusinessError) => {
      console.error(`Failed to startAbility. Code: ${err.code}, message: ${err.message}`);
    });
}
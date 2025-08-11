import { AppStorageV2 } from '@kit.ArkUI';
import { StorageDefaultCreator, TypeConstructorWithArgs } from '@ohos.arkui.StateManagement';
import { abilityKey } from '../utils/AbilityUtils';

export class AbilityStorage {
  public static connect<T extends object>(
    context: UIContext | Context,
    type: TypeConstructorWithArgs<T>,
    key: string,
    defaultCreator: StorageDefaultCreator<T>
  ): T | undefined {
    return AppStorageV2.connect(
      type,
      `${abilityKey(context)}_${key}`,
      defaultCreator
    )
  }

  public static remove(context: UIContext | Context, key: string) {
    AppStorageV2.remove(`${abilityKey(context)}_${key}`)
  }

  public static keys(context: UIContext | Context): string[] {
    let filteredKeys = new Array<string>()
    let identifier = abilityKey(context)
    for (let key of AppStorageV2.keys()) {
      if (key.startsWith(`${identifier}_`)) {
        filteredKeys.push(key)
      }
    }
    return filteredKeys
  }
}
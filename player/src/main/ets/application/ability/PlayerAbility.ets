import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { WindowManager } from '../../ui/manager/WindowManager';
import { SystemContext } from '../../context/SystemContext';
import { PreferenceContext } from '../../context/PreferenceContext';
import { JSON } from '@kit.ArkTS';
import { randomString } from '../../utils/StringUtils';

export default class PlayerAbility extends UIAbility {

  private static contextToAbilityMappings: Map<common.UIAbilityContext, PlayerAbility> = new Map()
  private key: string | undefined = undefined

  public getIdentifier(): string {
    return this.key!
  }

  public static getAbility(context: common.UIAbilityContext): PlayerAbility {
    return PlayerAbility.contextToAbilityMappings.get(context)!
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    PlayerAbility.contextToAbilityMappings.set(this.context, this)
    this.key = randomString(32)
  }

  onDestroy(): void {
    PlayerAbility.contextToAbilityMappings.delete(this.context)
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindow()
      .then((window: window.Window) => {
        WindowManager.init(this.context, window)
      })
    windowStage.loadContent('ui/pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
    });
  }

  onWindowStageDestroy(): void {

  }

  onForeground(): void {

  }

  onBackground(): void {

  }

}

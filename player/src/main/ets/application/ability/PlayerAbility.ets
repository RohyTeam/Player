import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { WindowManager } from '../../ui/manager/WindowManager';
import { JSON } from '@kit.ArkTS';
import { randomString } from '../../utils/StringUtils';
import { AbilityStorage } from '../../storage/AbilityStorage';
import { PlayerContext } from '../../player/PlayerContext';
import { MetadataCache } from '../../cache/MetadataCache';
import { LocalFileVideoSource } from '../../player/VideoSource';
import { fileUri } from '@kit.CoreFileKit';
import { Wanter } from '../../context/WantAnnouncer';

export default class PlayerAbility extends UIAbility {
  private static contextToAbilityMappings: Map<common.UIAbilityContext, PlayerAbility> = new Map()
  private key: string | undefined = undefined

  public getIdentifier(): string {
    return this.key!
  }

  public static getAbility(context: common.UIAbilityContext): PlayerAbility {
    return PlayerAbility.contextToAbilityMappings.get(context)!
  }

  async onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    PlayerAbility.contextToAbilityMappings.set(this.context, this)
    if (await this.resolveWantUri(want.uri)) {
      Wanter.announced = true
    }
  }

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    this.key = randomString(32)
    PlayerAbility.contextToAbilityMappings.set(this.context, this)
    await this.resolveWantUri(want.uri)
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

  private async resolveWantUri(url: string | undefined): Promise<boolean> {
    if (url == undefined) {
      return false
    }
    if (!url.startsWith("file://")) {
      return false
    }
    if (url.startsWith("file://media")) {
      return false
    }
    let playerContext = AbilityStorage.connect(
      this.context,
      PlayerContext,
      "player_context",
      () => new PlayerContext()
    )!
    let metadata = await MetadataCache.getOrCreate(url)
    playerContext.video = true
    playerContext.videoSource = new LocalFileVideoSource(
      metadata,
      url,
      new fileUri.FileUri(url).name
    )
    return true
  }
}

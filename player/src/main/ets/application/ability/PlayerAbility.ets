import { AbilityConstant, common, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { WindowManager } from '../../ui/manager/WindowManager';
import { JSON } from '@kit.ArkTS';
import { randomString } from '../../utils/StringUtils';
import { AbilityStorage } from '../../storage/AbilityStorage';
import { PlayerContext } from '../../player/PlayerContext';
import { MetadataFetcher } from '../../metadata/MetadataFetcher';
import { LocalFileVideoSource } from '../../player/VideoSource';
import { fileUri } from '@kit.CoreFileKit';
import { Wanter } from '../../context/WantAnnouncer';
import { setColorMode } from '../../utils/ConfigurationUtils';
import { Pref } from '../../context/PreferenceContext';
import { SavedVideoMetadata } from '../../metadata/SavedVideoMetadata';
import { VideoMetadataManager } from '../../metadata/VideoMetadataManager';
import { sha256 } from '../../utils/HashUtils';
import { ensurePath } from '../../utils/FileUtils';

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

    setColorMode(this.context, Pref.colorMode)
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
    let playerContext = PlayerContext.reach(this.context)
    let savedMetadata: SavedVideoMetadata
    if (VideoMetadataManager.exists(sha256(`files:${url}`))) {
      savedMetadata = VideoMetadataManager.load(sha256(`files:${url}`))!
    } else {
      let metadata = await MetadataFetcher.fetch(ensurePath(url), url.startsWith("files://media"))
      savedMetadata = VideoMetadataManager.save(
        sha256(`files:${url}`),
        false,
        url,
        metadata
      )!
    }
    playerContext.video = true
    playerContext.videoSource = new LocalFileVideoSource(
      false,
      savedMetadata,
      url,
      new fileUri.FileUri(url).name
    )
    return true
  }
}

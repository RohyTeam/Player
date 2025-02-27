import { common, Want } from '@kit.AbilityKit';
import { AVVideoPlayer } from './player/AVVideoPlayer';
import { deviceInfo } from '@kit.BasicServicesKit';
import { FileUtil } from '@pura/harmony-utils';
import { IjkVideoPlayer } from './player/IjkVideoPlayer';
import { PlayerMetadata } from '../util/PlayerUtil';

export class EventData {
  launchWant: Want | undefined = undefined
}

@Entry
@Component
struct VideoIndex {
  @State
  private want: Want | undefined = undefined
  @State
  private title: string = ''
  @State
  private url: string | undefined = undefined
  @State
  private hash: string | undefined = undefined // TODO: 注意，虽然这个参数叫 hash，实际上在 webdav 支持更新后被替换为了 identity
  @State
  private metadata: PlayerMetadata | undefined = undefined
  @State
  private videoHolder: string | undefined = undefined
  @State
  private isContinuation: boolean = false
  @State
  private backTrigger: boolean = false
  @StorageLink('appColorMode')
  colorMode: string = "system";
  @StorageLink('preferFFmpeg')
  preferFFmpeg: boolean = false;

  aboutToAppear(): void {
    console.error("trying to play video")
    let eventData = new EventData()
    getContext(this).eventHub.emit('getAbilityData', eventData)
    let want = eventData.launchWant!
    this.want = want
    if (want.parameters!['originalDevice'] != undefined) {
      this.isContinuation = true
      console.error("find continue video")
      if (want.parameters!.originalDevice as string != deviceInfo.ODID) {
        console.error(`is remote file, url is: ${FileUtil.getUriFromPath(`${getContext(this)
          .distributedFilesDir}/${want.parameters!.hash}.vid`)}`)
        this.url = `dfs:${getContext(this).distributedFilesDir}/${want.parameters!.hash}.vid`
        this.videoHolder = want.parameters!.videoHolder as string
      } else {
        this.url = want.parameters!.url as string
      }
    } else {
      this.url = want.parameters!.url as string
    }
    this.title = want.parameters!.title as string
    this.hash = want.parameters!.hash as string
    this.metadata = JSON.parse(want.parameters!.metadata as string) as PlayerMetadata
  }

  build() {
    WithTheme({
      colorMode: this.colorMode == "system" ? ThemeColorMode.SYSTEM :
        this.colorMode == "dark" ? ThemeColorMode.DARK : ThemeColorMode.LIGHT,
    }) {
      Stack() {
        if (this.want != undefined) {
          if (this.preferFFmpeg) {
            IjkVideoPlayer({
              want: this.want,
              title: this.title,
              url: this.url,
              identity: this.hash,
              metadata: this.metadata,
              videoHolder: this.videoHolder,
              isContinuation: this.isContinuation,
              backTrigger: this.backTrigger,
            })
          } else {
            AVVideoPlayer({
              want: this.want,
              title: this.title,
              url: this.url,
              identity: this.hash,
              metadata: this.metadata,
              videoHolder: this.videoHolder,
              isContinuation: this.isContinuation,
              backTrigger: this.backTrigger,
            })
          }
        }
      }
      .width("100%")
      .height("100%")
    }
  }

  onBackPress(): boolean | void {
    this.backTrigger = true;
    (getContext(this) as common.UIAbilityContext).terminateSelf()
      .then(() => {
      })
  }
}
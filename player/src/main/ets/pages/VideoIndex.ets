import { common, Want } from '@kit.AbilityKit';
import { AVVideoPlayer } from './player/AVVideoPlayer';
import { deviceInfo } from '@kit.BasicServicesKit';
import { IjkVideoPlayer } from './player/IjkVideoPlayer';
import { PlayerMetadata } from '../util/PlayerUtil';
import { Rlog } from '../log/Rlog';

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
    Rlog.debug(`render: VideoIndex`)
    Rlog.debug(`analysing provided want data`)
    let eventData = new EventData()
    getContext(this).eventHub.emit('getAbilityData', eventData)
    let want = eventData.launchWant!
    this.want = want
    if (want.parameters!['originalDevice'] != undefined) {
      this.isContinuation = true
      if (want.parameters!.originalDevice as string != deviceInfo.ODID) {
        let originalFileUri = want.parameters!.originalVidUri as string
        if (originalFileUri.startsWith('file://')) {
          Rlog.debug(`playing a video from continuation (file on another device)`)
          this.url = `dfs:${getContext(this).distributedFilesDir}/${want.parameters!.hash}.vid`
        } else {
          Rlog.debug(`playing a video from continuation (file is on internet)`)
          this.url = originalFileUri
        }
        this.videoHolder = want.parameters!.videoHolder as string
      } else {
        this.url = want.parameters!.url as string
        if (this.url.startsWith('file://')) {
          Rlog.debug(`playing a video from continuation (file on this device)`)
        } else {
          Rlog.debug(`playing a video from continuation (file is on internet)`)
        }
      }
    } else {
      Rlog.debug(`playing a video saved in local database (local or network video is not clear at this stage)`)
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
import { MetadataCache } from '../../../cache/MetadataCache';
import { LocalFiles, Photos } from '../../../filemanagement/FileSource';
import { PlayerContext } from '../../../player/PlayerContext';
import { LocalFileVideoSource, PhotosVideoSource } from '../../../player/VideoSource';
import { AbilityStorage } from '../../../storage/AbilityStorage';
import { CircleIconButton } from '../../button/CircleIconButton';
import { OpenVideoSheet } from '../playlist/OpenVideoSheet';
import { fileUri } from '@kit.CoreFileKit';
import { ImportOrCreatePlaylistSheet } from '../playlist/ImportOrCreatePlaylistSheet';
import { SettingsSheet } from '../playlist/SettingsSheet';
import { SavedVideoMetadata } from '../../../metadata/SavedVideoMetadata';
import { VideoMetadataManager } from '../../../file/VideoMetadataManager';
import { sha256 } from '../../../utils/HashUtils';

@ComponentV2
export struct IndexMenuButtons {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Local
  private showImportVideoSheet: boolean = false
  @Local
  private showOpenVideoSheet: boolean = false
  @Local
  private showSettingsSheet: boolean = false
  @Local
  playerContext: PlayerContext = AbilityStorage.connect(
    this.getUIContext(),
    PlayerContext,
    "player_context",
    () => new PlayerContext()
  )!

  build() {
    Row() {
      CircleIconButton({
        icon: $r("sys.symbol.plus"),
        buttonMargin: {
          right: 8
        },
        clickCallback: () => {
          this.showImportVideoSheet = true
        }
      })
        .bindSheet(
          this.showImportVideoSheet!!,
          this.ImportOrCreatePlaylistSheet,
          {
            backgroundColor: $r("app.color.rohy_background"),
            height: SheetSize.FIT_CONTENT,
            dragBar: false,
            shadow: ShadowStyle.OUTER_DEFAULT_MD,
            showClose: true,
            preferType: SheetType.CENTER,
            enableOutsideInteractive: false,
            mode: SheetMode.OVERLAY,
            onWillDismiss: () => {
              this.showImportVideoSheet = false
            },
            title: {
              title: $r("app.string.import_or_create_playlist"),
              subtitle: $r("app.string.not_implemented")
            }
          }
        )
      CircleIconButton({
        icon: $r("sys.symbol.arrow_right_folder_circle"),
        buttonMargin: {
          right: 8
        },
        clickCallback: () => {
          this.showOpenVideoSheet = true
        }
      })
        .bindSheet(
          this.showOpenVideoSheet!!,
          this.OpenVideoSheet,
          {
            backgroundColor: $r("app.color.rohy_background"),
            height: SheetSize.FIT_CONTENT,
            dragBar: false,
            shadow: ShadowStyle.OUTER_DEFAULT_MD,
            showClose: true,
            preferType: SheetType.CENTER,
            enableOutsideInteractive: false,
            mode: SheetMode.OVERLAY,
            onWillDismiss: () => {
              this.showOpenVideoSheet = false
            },
            title: {
              title: $r("app.string.open_video"),
              subtitle: $r("app.string.choose_location"),
            }
          }
        )
      CircleIconButton({
        icon: $r("sys.symbol.gearshape"),
        buttonMargin: {
          right: 8
        },
        clickCallback: () => {
          this.showSettingsSheet = true
        }
      })
        .bindSheet(
          this.showSettingsSheet!!,
          this.SettingsSheet,
          {
            backgroundColor: $r("app.color.rohy_background"),
            height: SheetSize.LARGE,
            dragBar: false,
            shadow: ShadowStyle.OUTER_DEFAULT_MD,
            showClose: true,
            preferType: SheetType.CENTER,
            enableOutsideInteractive: false,
            mode: SheetMode.OVERLAY,
            onWillDismiss: () => {
              this.showSettingsSheet = false
            },
            title: {
              title: $r("app.string.settings"),
              subtitle: $r("app.string.not_implemented")
            }
          }
        )
    }
    .margin({
      right: 8,
      top: 8
    })
  }

  @Builder
  private SettingsSheet() {
    SettingsSheet({
      close: () => {
        this.showSettingsSheet = false
      }
    })
  }

  @Builder
  private ImportOrCreatePlaylistSheet() {
    ImportOrCreatePlaylistSheet({
      hideChooser: () => {
        this.showOpenVideoSheet = false
      },
      onPick: async (files) => {

      }
    })
  }

  @Builder
  private OpenVideoSheet() {
    OpenVideoSheet({
      hideChooser: () => {
        this.showOpenVideoSheet = false
      },
      onPick: async (file) => {
        let savedMetadata: SavedVideoMetadata
        if (file.source == LocalFiles) {
          if (VideoMetadataManager.exists(sha256(`files:${file.url}`))) {
            savedMetadata = VideoMetadataManager.load(sha256(`files:${file.url}`))!
          } else {
            let metadata = await MetadataCache.getOrCreate(file.url)
            savedMetadata = VideoMetadataManager.save(
              sha256(`files:${file.url}`),
              false,
              file.url,
              metadata
            )!
          }
          this.playerContext.video = true
          this.playerContext.videoSource = new LocalFileVideoSource(
            false,
            savedMetadata,
            file.url,
            new fileUri.FileUri(file.url).name
          )
        } else if (file.source == Photos) {
          if (VideoMetadataManager.exists(sha256(`photos:${file.url}`))) {
            savedMetadata = VideoMetadataManager.load(sha256(`photos:${file.url}`))!
          } else {
            let metadata = await MetadataCache.getOrCreate(file.url)
            savedMetadata = VideoMetadataManager.save(
              sha256(`photos:${file.url}`),
              false,
              file.url,
              metadata
            )!
          }
          this.playerContext.video = true
          this.playerContext.videoSource = new PhotosVideoSource(
            savedMetadata,
            file.url,
            file.title ?? new fileUri.FileUri(file.url).name
          )
        } else {
          return
        }
        this.indexNavigator.pushPath({ name: "Player" })
      }
    })
  }
}
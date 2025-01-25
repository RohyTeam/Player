import { VideoLibraryDatabase } from './VideoLibraryDatabase';
import { common } from '@kit.AbilityKit';
import { SubtitleLibraryDatabase } from './SubtitleLibraryDatabase';

export class DatabaseManager {
  public static init(context: common.Context) {
    VideoLibraryDatabase.init(context)
    SubtitleLibraryDatabase.init(context)
  }
}
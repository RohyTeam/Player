import { VideoLibraryDatabase } from './VideoLibraryDatabase';
import { common } from '@kit.AbilityKit';
import { SubtitleLibraryDatabase } from './SubtitleLibraryDatabase';
import { FontLibraryDatabase } from './FontLibraryDatabase';

export class DatabaseManager {
  public static init(context: common.Context) {
    VideoLibraryDatabase.init(context)
    SubtitleLibraryDatabase.init(context)
    FontLibraryDatabase.init(context)
  }
}
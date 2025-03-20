import { VideoLibraryDatabase } from './VideoLibraryDatabase';
import { common } from '@kit.AbilityKit';
import { SubtitleLibraryDatabase } from './SubtitleLibraryDatabase';
import { FontLibraryDatabase } from './FontLibraryDatabase';
import { WebDAVDatabase } from './WebDAVDatabase';
import { Rlog } from '../log/Rlog';

export class DatabaseManager {

  public static init(context: common.Context) {
    Rlog.debug("start: invoke of DatabaseManager#init function")
    VideoLibraryDatabase.init(context)
    SubtitleLibraryDatabase.init(context)
    FontLibraryDatabase.init(context)
    WebDAVDatabase.init(context)
    Rlog.debug("start: invoke of DatabaseManager#init function")
  }

}
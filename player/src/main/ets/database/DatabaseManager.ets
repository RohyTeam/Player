import { VideoLibraryDatabase } from './VideoLibraryDatabase';
import { common } from '@kit.AbilityKit';
import { SubtitleLibraryDatabase } from './SubtitleLibraryDatabase';
import { FontLibraryDatabase } from './FontLibraryDatabase';
import { WebDAVDatabase } from './WebDAVDatabase';
import { Rlog } from '../log/Rlog';
import { relationalStore } from '@kit.ArkData';

export class DatabaseManager {
  public static init(context: common.Context) {
    Rlog.debug("start: invoke of DatabaseManager#init function")
    VideoLibraryDatabase.init(context)
    SubtitleLibraryDatabase.init(context)
    FontLibraryDatabase.init(context)
    WebDAVDatabase.init(context)
    Rlog.debug("start: invoke of DatabaseManager#init function")
  }

  public static clearAllDatabase(context: common.Context): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.deleteRdbStore(context, "videoLibrary.db")
        .then(() => {
          Rlog.debug(`VideoLibraryDatabase deleted`)
          relationalStore.deleteRdbStore(context, "fontlibrary.db")
            .then(() => {
              Rlog.debug(`FontLibraryDatabase deleted`)
              relationalStore.deleteRdbStore(context, "subtitleLibrary.db")
                .then(() => {
                  Rlog.debug(`SubtitleLibraryDatabase deleted`)
                  relationalStore.deleteRdbStore(context, "webdav.db")
                    .then(() => {
                      Rlog.debug(`WebDAVDatabase deleted`)
                      resultReturner()
                    })
                })
            })
        })
    })
  }
}
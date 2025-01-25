import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { fileShare, hash } from '@kit.CoreFileKit';
import { FileUtil } from '@pura/harmony-utils';
import { VideoEntity } from '../entity/VideoEntity';
import { BusinessError } from '@kit.BasicServicesKit';

export class VideoLibraryDatabase {
  private static SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS VideoLibrary (' +
    'LOCATION TEXT,' +
    'TITLE TEXT,' +
    'ADDED_TIME INTEGER,' +
    'FILE_HASH TEXT,' +
    'FILE_SOURCE TEXT' +
    ');';
  private static databaseConfig: relationalStore.StoreConfig = {
    name: 'videoLibrary.db',
    securityLevel: relationalStore.SecurityLevel.S2,
    encrypt: true
  }

  public static init(context: common.Context) {
    relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
      if (err) {
        hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
        return;
      }

      if (store.version === 0) {
        store.executeSql(VideoLibraryDatabase.SQL_CREATE_TABLE)
        store.version = 1
      } else if (store.version == 1) {
        store.executeSql('\n' +
          'ALTER TABLE VideoLibrary ADD COLUMN FILE_SOURCE TEXT DEFAULT `LOCAL_FILE`;');
        store.version = 2
      }

      hilog.debug(0x0, "database", "created video database")
    })
  }

  public static addFromLocalFile(context: common.Context, uri: string): Promise<VideoEntity> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        fileShare.persistPermission([
          {
            uri: uri,
            operationMode: 0b1
          }
        ])
          .then(() => {
            let path = FileUtil.getFilePath(uri)

            hash.hash(path, "sha256")
              .then((hashValue) => {
                store.insert(
                  "VideoLibrary",
                  {
                    "LOCATION": uri,
                    "TITLE": FileUtil.getFileName(uri),
                    "ADDED_TIME": Date.now(),
                    "FILE_HASH": hashValue,
                    "FILE_SOURCE": "LOCAL_FILE"
                  }
                ).then(() => {
                  resultReturner({
                    uri: uri,
                    title: FileUtil.getFileName(uri),
                    addedTime: Date.now(),
                    hash: hashValue,
                    fileSource: "local_file"
                  })
                })
              })
          })
          .catch(() => {

          })
      })
    })
  }

  public static addFromPhotos(context: common.Context, uri: string, displayName: string,
    photoHash: string): Promise<VideoEntity> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        store.insert(
          "VideoLibrary",
          {
            "LOCATION": uri,
            "TITLE": displayName,
            "ADDED_TIME": Date.now(),
            "FILE_HASH": photoHash,
            "FILE_SOURCE": "PHOTOS"
          }
        ).then(() => {
          resultReturner({
            uri: uri,
            title: displayName,
            addedTime: Date.now(),
            hash: photoHash,
            fileSource: "photos"
          })
        })
      })
    })
  }

  public static unsafeList(context: common.Context): Promise<Array<VideoEntity>> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        store.query(new relationalStore.RdbPredicates("VideoLibrary"), async (err: BusinessError, resultSet) => {
          if (err) {
            hilog.error(0x2, "database", `Failed to query data. Code:${err.code}, message:${err.message}`)
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            console.error("there are no data in database")
            resultReturner(new Array())
          } else {
            let videos = new Array<VideoEntity>()

            while (resultSet.goToNextRow()) {
              let video: VideoEntity = {
                uri: resultSet.getString(resultSet.getColumnIndex("LOCATION")),
                title: resultSet.getString(resultSet.getColumnIndex("TITLE")),
                addedTime: resultSet.getLong(resultSet.getColumnIndex("ADDED_TIME")),
                hash: resultSet.getString(resultSet.getColumnIndex("FILE_HASH")),
                fileSource: resultSet.getString(resultSet.getColumnIndex("FILE_SOURCE")).toLowerCase(),
              }
              videos.push(video)
            }

            resultReturner(videos)
          }
        })
      })
    })
  }

  public static deleteByHash(context: common.Context, hashValue: string): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        store.delete(
          new relationalStore.RdbPredicates("VideoLibrary")
            .equalTo("FILE_HASH", hashValue)
        )
          .then((num: number) => {
            resultReturner()
          })
      })
    })
  }

  public static updateNameByHash(context: common.Context, hashValue: string, newTitle: string): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        store.update(
          {
            "TITLE": newTitle
          },
          new relationalStore.RdbPredicates("VideoLibrary")
            .equalTo("FILE_HASH", hashValue)
        )
          .then((num: number) => {
            resultReturner()
          })
      })
    })
  }
}
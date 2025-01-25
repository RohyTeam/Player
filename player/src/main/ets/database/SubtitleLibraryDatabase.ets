import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { fileShare, hash } from '@kit.CoreFileKit';
import { FileUtil } from '@pura/harmony-utils';
import { BusinessError } from '@kit.BasicServicesKit';
import { JSON } from '@kit.ArkTS';

export class SubtitleLibraryDatabase {
  private static SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS SubtitleLibrary (' +
    'FILE_HASH TEXT,' +
    'SUBTITLE_HASH TEXT,' +
    'PATH TEXT' +
    ');';
  private static databaseConfig: relationalStore.StoreConfig = {
    name: 'subtitleLibrary.db',
    securityLevel: relationalStore.SecurityLevel.S2,
    encrypt: true
  }

  public static init(context: common.Context) {
    relationalStore.getRdbStore(context, SubtitleLibraryDatabase.databaseConfig, (err, store) => {
      if (err) {
        hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
        return;
      }
      /*
            store.executeSync("DROP TABLE SubtitleLibrary;")
            store.executeSql(SubtitleLibraryDatabase.SQL_CREATE_TABLE)*/

      if (store.version === 0) {
        store.executeSql(SubtitleLibraryDatabase.SQL_CREATE_TABLE)
        store.version = 1
      }

      hilog.debug(0x0, "database", "created subtitle database")
    })
  }

  public static add(context: common.Context, fileHash: string, uri: string): Promise<[string, string]> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, SubtitleLibraryDatabase.databaseConfig, (err, store) => {
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
            hash.hash(FileUtil.getFilePath(uri), "sha256")
              .then((subtitleHash) => {
                store.insert(
                  "SubtitleLibrary",
                  {
                    "FILE_HASH": fileHash,
                    "SUBTITLE_HASH": subtitleHash,
                    "PATH": uri
                  }
                ).then(() => {
                  resultReturner([uri, subtitleHash])
                })
              })
          })
      })
    })
  }

  public static get(context: common.Context, fileHash: string): Promise<Array<string>> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, SubtitleLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        store.query(new relationalStore.RdbPredicates("SubtitleLibrary")
          .equalTo("FILE_HASH", fileHash), async (err: BusinessError, resultSet) => {
          if (err) {
            hilog.error(0x2, "database", `Failed to query data. Code:${err.code}, message:${err.message}`)
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            console.error("there are no data in database")
            resultReturner(new Array())
          } else {
            let subtitles = new Array<string>()

            console.error(`starting listing data`)
            while (resultSet.goToNextRow()) {
              let uri = resultSet.getString(resultSet.getColumnIndex("PATH"))
              let subtitleHash = resultSet.getString(resultSet.getColumnIndex("SUBTITLE_HASH"))
              try {
                console.error(`activating data`)
                await fileShare.activatePermission([{
                  uri: uri,
                  operationMode: 0b1
                }])
                let hashValue = await hash.hash(FileUtil.getFilePath(uri), "sha256")
                if (hashValue != subtitleHash) {
                  SubtitleLibraryDatabase.deleteBySubtitleHash(context, subtitleHash)
                } else {
                  subtitles.push(uri)
                }
              } catch (e) {
                console.error(`error happend: ${JSON.stringify(e)}`)
              }
            }
            console.error(`returning data`)
            resultReturner(subtitles)
          }
        })
      })
    })
  }

  public static deleteBySubtitleHash(context: common.Context, hashValue: string): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, SubtitleLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        store.delete(
          new relationalStore.RdbPredicates("SubtitleLibrary")
            .equalTo("SUBTITLE_HASH", hashValue)
        )
          .then((num: number) => {
            resultReturner()
          })
      })
    })
  }
}
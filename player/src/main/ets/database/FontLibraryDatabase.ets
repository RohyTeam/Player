import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { FontEntity } from '../entity/FontEntity';
import { BusinessError } from '@kit.BasicServicesKit';
import { FileUtil } from '@pura/harmony-utils';
import { fileShare, hash } from '@kit.CoreFileKit';
import SubtitleManager from 'librohy_subtitle.so';

export class FontLibraryDatabase {
  private static SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS FontLibrary (' +
    'FONT_NAME TEXT,' +
    'FILE_HASH TEXT,' +
    'USE INTEGER,' +
    'PATH TEXT' +
    ');';
  private static databaseConfig: relationalStore.StoreConfig = {
    name: 'fontlibrary.db',
    securityLevel: relationalStore.SecurityLevel.S2,
    encrypt: true
  }

  public static init(context: common.Context) {
    relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
      if (err) {
        hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
        return;
      }
      if (store.version === 0) {
        store.executeSql(FontLibraryDatabase.SQL_CREATE_TABLE)
        store.version = 1
      }

      hilog.debug(0x0, "database", "created font database")
    })
  }

  public static add(context: common.Context, uri: string): Promise<FontEntity> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
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
            let fontName = SubtitleManager.Subtitle_GetFontFamilyName(path)
            console.error(`js side name is ${fontName}`)
            hash.hash(path, "sha256")
              .then((fontHash) => {
                store.insert(
                  "FontLibrary",
                  {
                    "FONT_NAME": fontName,
                    "FILE_HASH": fontHash,
                    "USE": 1,
                    "PATH": uri
                  }
                ).then(() => {
                  resultReturner({
                    familyName: fontName!!,
                    hash: fontHash,
                    uri: uri,
                    on: true
                  })
                })
              })
          })
      })
    })
  }

  public static unsafeList(context: common.Context): Promise<Array<FontEntity>> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        store.query(new relationalStore.RdbPredicates("FontLibrary"), async (err: BusinessError, resultSet) => {
          if (err) {
            hilog.error(0x2, "database", `Failed to query data. Code:${err.code}, message:${err.message}`)
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            console.error("there are no data in database")
            resultReturner(new Array())
          } else {
            let fonts = new Array<FontEntity>()

            while (resultSet.goToNextRow()) {
              let font: FontEntity = {
                familyName: resultSet.getString(resultSet.getColumnIndex("FONT_NAME")),
                hash: resultSet.getString(resultSet.getColumnIndex("FILE_HASH")),
                on: resultSet.getLong(resultSet.getColumnIndex("USE")) == 1,
                uri: resultSet.getString(resultSet.getColumnIndex("PATH")),
              }
              fonts.push(font)
            }

            resultReturner(fonts)
          }
        })
      })
    })
  }

  public static deleteByFontHash(context: common.Context, hashValue: string): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        store.delete(
          new relationalStore.RdbPredicates("FontLibrary")
            .equalTo("FILE_HASH", hashValue)
        )
          .then((num: number) => {
            resultReturner()
          })
      })
    })
  }

  public static changeUseByHash(context: common.Context, hashValue: string, on: boolean): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        store.update(
          {
            "USE": on ? 1 : 0
          },
          new relationalStore.RdbPredicates("FontLibrary")
            .equalTo("FILE_HASH", hashValue)
        )
          .then((num: number) => {
            resultReturner()
          })
      })
    })
  }
}
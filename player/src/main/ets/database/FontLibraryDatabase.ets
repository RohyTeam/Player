import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { FontEntity } from '../entity/FontEntity';
import { BusinessError } from '@kit.BasicServicesKit';
import { FileUtil } from '@pura/harmony-utils';
import { fileShare, hash } from '@kit.CoreFileKit';
import SubtitleManager from 'librohy_subtitle.so';
import { RLogger } from '../log/Rlog';
import { font } from '@kit.ArkUI';

let LOGGER = RLogger.of('FontLibraryDatabase')

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
    LOGGER.debug("start: invoke of FontLibraryDatabase#init function")
    relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
      if (err) {
        LOGGER.error(`failed to get RdbStore`, {
          error: err
        })
        LOGGER.debug("end: invoke of FontLibraryDatabase#init function")
        return;
      }
      if (store.version === 0) {
        store.executeSql(FontLibraryDatabase.SQL_CREATE_TABLE)
        store.version = 1
        LOGGER.debug(`initialized font library database`)
      } else {
        LOGGER.debug(`font library database has already been initialized, nothing to do`)
      }

      LOGGER.debug("end: invoke of FontLibraryDatabase#init function")
    })
  }

  public static add(context: common.Context, uri: string): Promise<FontEntity> {
    LOGGER.debug("start: invoke of FontLibraryDatabase#add function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of FontLibraryDatabase#add function")
          return;
        }

        fileShare.persistPermission([
          {
            uri: uri,
            operationMode: 0b1
          }
        ])
          .then(() => {
            LOGGER.debug(`font file permission persisted`)
            let path = FileUtil.getFilePath(uri)
            let fontName = SubtitleManager.Subtitle_GetFontFamilyName(path)
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
                  LOGGER.debug("end: invoke of FontLibraryDatabase#add function")
                  resultReturner({
                    familyName: fontName!!,
                    hash: fontHash,
                    uri: uri,
                    on: true
                  })
                })
                  .catch((err: BusinessError) => {
                    LOGGER.error(`failed to insert font library data`, {
                      error: err
                    })
                    LOGGER.debug("end: invoke of FontLibraryDatabase#add function")
                })
              })
              .catch((err: BusinessError) => {
                LOGGER.error(`failed to hash font file`, {
                  error: err
                })
                LOGGER.debug("end: invoke of FontLibraryDatabase#add function")
              })
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to persist permission`, {
              error: err
            })
            LOGGER.debug("end: invoke of FontLibraryDatabase#add function")
          })
      })
    })
  }

  public static unsafeList(context: common.Context): Promise<Array<FontEntity>> {
    LOGGER.debug("start: invoke of FontLibraryDatabase#unsafeList function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of FontLibraryDatabase#unsafeList function")
          return;
        }
        store.query(new relationalStore.RdbPredicates("FontLibrary"), async (err: BusinessError, resultSet) => {
          if (err) {
            LOGGER.error(`failed to query data`, {
              error: err
            })
            LOGGER.debug("end: invoke of FontLibraryDatabase#unsafeList function")
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            LOGGER.debug(`there is no data in font library database`)
            LOGGER.debug("end: invoke of FontLibraryDatabase#unsafeList function")
            resultReturner(new Array())
          } else {
            LOGGER.debug(`${resultSet.rowCount} data queried in font library database`)
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

            LOGGER.debug(`${fonts.length} fonts found in font library database`)
            LOGGER.debug("end: invoke of FontLibraryDatabase#unsafeList function")
            resultReturner(fonts)
          }
        })
      })
    })
  }

  public static deleteByFontHash(context: common.Context, hashValue: string): Promise<void> {
    LOGGER.debug("start: invoke of FontLibraryDatabase#deleteByFontHash function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of FontLibraryDatabase#deleteByFontHash function")
          return;
        }

        store.delete(
          new relationalStore.RdbPredicates("FontLibrary")
            .equalTo("FILE_HASH", hashValue)
        )
          .then((num: number) => {
            LOGGER.debug(`delete action affected ${num} rows of data`)
            LOGGER.debug("end: invoke of FontLibraryDatabase#deleteByFontHash function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to delete font data`, {
              error: err
            })
            LOGGER.debug("end: invoke of FontLibraryDatabase#deleteByFontHash function")
          })
      })
    })
  }

  public static changeUseByHash(context: common.Context, hashValue: string, on: boolean): Promise<void> {
    LOGGER.debug("start: invoke of FontLibraryDatabase#changeUseByHash function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, FontLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of FontLibraryDatabase#changeUseByHash function")
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
            LOGGER.debug(`update action affected ${num} rows of data`)
            LOGGER.debug("end: invoke of FontLibraryDatabase#changeUseByHash function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to update font data`, {
              error: err
            })
            LOGGER.debug("end: invoke of FontLibraryDatabase#changeUseByHash function")
          })
      })
    })
  }
}
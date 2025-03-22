import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { BusinessError } from '@kit.BasicServicesKit';
import { WebDAVAuthorization } from '../entity/WebDAVEntity';
import { WebDAVVideoSource } from '../entity/VideoEntity';
import { image } from '@kit.ImageKit';
import { pixelMapToArrayBuffer } from '../util/ImageUtil';
import resourceManager from '@ohos.resourceManager';
import { VirtualNode } from '../pages/components/VirtualFilePicker';
import { WebDAVClient } from '../lib/webdav_client/WebDAVClient';
import { RLogger } from '../log/Rlog';

let LOGGER = RLogger.of('WebDAVDatabase')

export class WebDAVDatabase {
  private static SQL_CREATE_WEBDAV_SERVER_TABLE = 'CREATE TABLE IF NOT EXISTS WebDAVServers (' +
    'SERVER_URL TEXT,' +
    'DISPLAY_NAME TEXT,' +
    'USERNAME TEXT,' +
    'PASSWORD TEXT' +
    ');';
  private static SQL_CREATE_WEVDAV_VIDEO_LIBRARY_TABLE = 'CREATE TABLE IF NOT EXISTS WebDAVVideoLibrary (' +
    'LOCATION TEXT,' +
    'TITLE TEXT,' +
    'ADDED_TIME INTEGER,' +
    'VIDEO_COVER BLOB,' +
    'VIDEO_LENGTH INTEGER,' +
    'VIDEO_WIDTH INTEGER,' +
    'VIDEO_HEIGHT INTEGER,' +
    'PLAYED_LENGTH INTEGER,' +
    'FILE_SOURCE TEXT' +
    ');';
  private static databaseConfig: relationalStore.StoreConfig = {
    name: 'webdav.db',
    securityLevel: relationalStore.SecurityLevel.S4, // 需要存储 webdav 的用户名及密码，属于高危信息，安全等级最高
    encrypt: true
  }

  public static init(context: common.Context) {
    LOGGER.debug("start: invoke of WebDAVDatabase#init function")
    relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
      if (err) {
        LOGGER.error(`failed to get RdbStore`, {
          error: err
        })
        LOGGER.debug("end: invoke of WebDAVDatabase#init function")
        return;
      }
      if (store.version === 0) {
        store.executeSql(WebDAVDatabase.SQL_CREATE_WEBDAV_SERVER_TABLE)
        store.executeSql(WebDAVDatabase.SQL_CREATE_WEVDAV_VIDEO_LIBRARY_TABLE)
        store.version = 1
        LOGGER.debug(`initialized webdav library database`)
      } else {
        LOGGER.debug(`webdav database has already been initialized, nothing to do`)
      }

      LOGGER.debug("end: invoke of WebDAVDatabase#init function")
    })
  }


  public static tryFetchByLocationAndUrl(context: common.Context, location: string,
    url: string): Promise<WebDAVVideoSource | undefined> {
    LOGGER.debug("start: invoke of WebDAVDatabase#tryFetchByLocationAndUrl function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#tryFetchByLocationAndUrl function")
          return;
        }

        store.query(new relationalStore.RdbPredicates("WebDAVVideoLibrary")
          .equalTo("FILE_SOURCE", url)
          .equalTo("LOCATION", location), async (err: BusinessError, resultSet) => {
          if (err) {
            LOGGER.error(`failed to query data from database`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#tryFetchByLocationAndUrl function")
            resultReturner(undefined)
            return
          }
          if (resultSet.rowCount == 0) {
            LOGGER.debug(`there is no data in webdav database`)
            LOGGER.debug("end: invoke of WebDAVDatabase#tryFetchByLocationAndUrl function")
            resultReturner(undefined)
          } else {
            LOGGER.debug(`queried ${resultSet.rowCount} data from webdav database${resultSet.rowCount > 1 ? ", multiple data queried, only the first data will be taken" : ""}`)
            resultSet.goToFirstRow()
            LOGGER.debug("end: invoke of WebDAVDatabase#tryFetchByLocationAndUrl function")
            resultReturner(
              new WebDAVVideoSource(
                resultSet.getString(resultSet.getColumnIndex("LOCATION")),
                resultSet.getString(resultSet.getColumnIndex("TITLE")),
                resultSet.getLong(resultSet.getColumnIndex("ADDED_TIME")),
                resultSet.getLong(resultSet.getColumnIndex("PLAYED_LENGTH")),
                resultSet.getLong(resultSet.getColumnIndex("VIDEO_LENGTH")),
                resultSet.getLong(resultSet.getColumnIndex("VIDEO_WIDTH")),
                resultSet.getLong(resultSet.getColumnIndex("VIDEO_HEIGHT")),
                resultSet.getBlob(resultSet.getColumnIndex("VIDEO_COVER")).buffer as ArrayBuffer,
                url
              )
            )
          }
        })
      })
    })

  }

  public static addVideo(context: common.Context, webdavClient: WebDAVClient, webdavUri: string, location: string,
    node: VirtualNode): Promise<WebDAVVideoSource> {
    LOGGER.debug("start: invoke of WebDAVDatabase#addVideo function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#addVideo function")
          return;
        }
        const resourceMgr: resourceManager.ResourceManager = context.resourceManager;
        resourceMgr.getRawFd('empty_video_cover.png')
          .then((rawFileDescriptor: resourceManager.RawFileDescriptor) => {
            const imageSource: image.ImageSource = image.createImageSource(rawFileDescriptor);

            let pixelMap = imageSource.createPixelMapSync()
            if (pixelMap == undefined) {
              LOGGER.error(`failed to create cover pixel map, which shouldn't happen!`)
              LOGGER.debug("end: invoke of WebDAVDatabase#addVideo function")
              return
            }
            pixelMapToArrayBuffer(pixelMap)
              .then((buffer) => {
                /* TODO：直接访问网络文件来获取到 metadata
                media.createAVMetadataExtractor()
                  .then((avMetadataExtractor: media.AVMetadataExtractor) => {
                    avMetadataExtractor.dataSrc = {

                    }
                  })*/
                store.insert(
                  "WebDAVVideoLibrary",
                  {
                    "LOCATION": location,
                    "TITLE": node.displayName,
                    "ADDED_TIME": Date.now(),
                    "FILE_SOURCE": webdavUri,
                    "VIDEO_LENGTH": -1,
                    "VIDEO_WIDTH": -1,
                    "VIDEO_HEIGHT": -1,
                    "PLAYED_LENGTH": -1,
                    "VIDEO_COVER": new Uint8Array(buffer)
                  }
                ).then(() => {
                  LOGGER.debug(`successful add a video from webdav server`)
                  resultReturner(new WebDAVVideoSource(
                    location,
                    node.displayName,
                    Date.now(),
                    -1,
                    -1,
                    -1,
                    -1,
                    buffer,
                    webdavUri
                  ))
                })
                  .catch((err: BusinessError) => {
                    LOGGER.error(`failed to insert webdav video data to database` ,{
                      error: err
                    })
                    LOGGER.debug("end: invoke of WebDAVDatabase#addVideo function")
                  })
              })
              .catch((err: BusinessError) => {
                LOGGER.error(`failed to convert cover pixel map to array buffer` ,{
                  error: err
                })
                LOGGER.debug("end: invoke of WebDAVDatabase#addVideo function")
              })
          })
          .catch((error: BusinessError) => {
            LOGGER.error(`failed to get default cover for remote video` ,{
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#addVideo function")
          })
      })
    })
  }

  public static addWebDAV(context: common.Context, authorization: WebDAVAuthorization): Promise<void> {
    LOGGER.debug("start: invoke of WebDAVDatabase#addWebDAV function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#addWebDAV function")
          return;
        }
        store.insert(
          "WebDAVServers",
          {
            "SERVER_URL": authorization.url,
            "DISPLAY_NAME": authorization.displayName,
            "USERNAME": authorization.account.username,
            "PASSWORD": authorization.account.password
          }
        )
          .then(() => {
            LOGGER.debug(`successfully added a webdav server`)
            LOGGER.debug("end: invoke of WebDAVDatabase#addWebDAV function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to add webdav server`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#addWebDAV function")
            resultReturner()
          })
      })
    })
  }

  public static unsafeListWebDAV(context: common.Context): Promise<Array<WebDAVAuthorization>> {
    LOGGER.debug("start: invoke of WebDAVDatabase#unsafeListWebDAV function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#unsafeListWebDAV function")
          return;
        }
        store.query(new relationalStore.RdbPredicates("WebDAVServers"), async (err: BusinessError, resultSet) => {
          if (err) {
            LOGGER.error(`failed to query data`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#unsafeListWebDAV function")
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            LOGGER.debug(`there is no data in webdav database`)
            LOGGER.debug("end: invoke of WebDAVDatabase#unsafeListWebDAV function")
            resultReturner(new Array())
          } else {
            LOGGER.debug(`queried ${resultSet.rowCount} webdav servers data from database`)

            let webdavs = new Array<WebDAVAuthorization>()

            while (resultSet.goToNextRow()) {
              webdavs.push({
                displayName: resultSet.getString(resultSet.getColumnIndex("DISPLAY_NAME")),
                url: resultSet.getString(resultSet.getColumnIndex("SERVER_URL")),
                account: {
                  username: resultSet.getString(resultSet.getColumnIndex("USERNAME")),
                  password: resultSet.getString(resultSet.getColumnIndex("PASSWORD"))
                },
                died: false
              })
            }

            LOGGER.debug(`unsafely listed ${webdavs.length} webdav server${webdavs.length <= 1 ? "" :
              "s"}`)
            LOGGER.debug("end: invoke of WebDAVDatabase#unsafeListWebDAV function")
            resultReturner(webdavs)
          }
        })
      })
    })
  }

  public static unsafeListVideos(context: common.Context): Promise<Array<WebDAVVideoSource>> {
    LOGGER.debug("start: invoke of WebDAVDatabase#unsafeListVideos function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#unsafeListVideos function")
          return;
        }
        store.query(new relationalStore.RdbPredicates("WebDAVVideoLibrary"), async (err: BusinessError, resultSet) => {
          if (err) {
            LOGGER.error(`failed to query data`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#unsafeListVideos function")
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            LOGGER.debug(`there is no data in webdav database`)
            LOGGER.debug("end: invoke of WebDAVDatabase#unsafeListVideos function")
            resultReturner(new Array())
          } else {
            LOGGER.debug(`queried ${resultSet.rowCount} webdav videos data from database`)

            let videos = new Array<WebDAVVideoSource>()

            while (resultSet.goToNextRow()) {
              let video: WebDAVVideoSource = new WebDAVVideoSource(
                resultSet.getString(resultSet.getColumnIndex("LOCATION")),
                resultSet.getString(resultSet.getColumnIndex("TITLE")),
                resultSet.getLong(resultSet.getColumnIndex("ADDED_TIME")),
                resultSet.getLong(resultSet.getColumnIndex("PLAYED_LENGTH")),
                resultSet.getLong(resultSet.getColumnIndex("VIDEO_LENGTH")),
                resultSet.getLong(resultSet.getColumnIndex("VIDEO_WIDTH")),
                resultSet.getLong(resultSet.getColumnIndex("VIDEO_HEIGHT")),
                resultSet.getBlob(resultSet.getColumnIndex("VIDEO_COVER")).buffer as ArrayBuffer,
                resultSet.getString(resultSet.getColumnIndex("FILE_SOURCE"))
              )
              videos.push(video)
            }

            LOGGER.debug(`unsafely listed ${videos.length} webdav video${videos.length <= 1 ? "" :
              "s"}`)
            LOGGER.debug("end: invoke of WebDAVDatabase#unsafeListVideos function")
            resultReturner(videos)
          }
        })
      })
    })
  }

  public static updateNameByLocationAndUrl(context: common.Context, newTitle: string, location: string,
    url: string): Promise<void> {
    LOGGER.debug("start: invoke of WebDAVDatabase#updateNameByLocationAndUrl function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#updateNameByLocationAndUrl function")
          return;
        }
        store.update(
          {
            "TITLE": newTitle
          },
          new relationalStore.RdbPredicates("WebDAVVideoLibrary")
            .equalTo("FILE_SOURCE", url)
            .equalTo("LOCATION", location)
        )
          .then((num: number) => {
            LOGGER.debug(`updated webdav video name`)
            LOGGER.debug(`update action affected ${num} rows of data`)
            LOGGER.debug("end: invoke of WebDAVDatabase#updateNameByLocationAndUrl function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to update webdav video name`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#updateNameByLocationAndUrl function")
          })
      })
    })
  }

  public static updatePlayedByLocationAndUrl(context: common.Context, played: number, location: string,
    url: string): Promise<void> {
    LOGGER.debug("start: invoke of WebDAVDatabase#updatePlayedByLocationAndUrl function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#updatePlayedByLocationAndUrl function")
          return;
        }
        store.update(
          {
            "PLAYED_LENGTH": played
          },
          new relationalStore.RdbPredicates("WebDAVVideoLibrary")
            .equalTo("FILE_SOURCE", url)
            .equalTo("LOCATION", location)
        )
          .then((num: number) => {
            LOGGER.debug(`updated webdav video played time`)
            LOGGER.debug(`update action affected ${num} rows of data`)
            LOGGER.debug("end: invoke of WebDAVDatabase#updatePlayedByLocationAndUrl function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to update webdav video played time`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#updatePlayedByLocationAndUrl function")
          })
      })
    })
  }

  public static updateWidthAndHeightByLocationAndUrl(context: common.Context, width: number, height: number,
    location: string, url: string): Promise<void> {
    LOGGER.debug("start: invoke of WebDAVDatabase#updateWidthAndHeightByLocationAndUrl function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#updateWidthAndHeightByLocationAndUrl function")
          return;
        }
        store.update(
          {
            "VIDEO_HEIGHT": height,
            "VIDEO_WIDTH": width,
          },
          new relationalStore.RdbPredicates("WebDAVVideoLibrary")
            .equalTo("FILE_SOURCE", url)
            .equalTo("LOCATION", location)
        )
          .then((num: number) => {
            LOGGER.debug(`updated webdav video width and height`)
            LOGGER.debug(`update action affected ${num} rows of data`)
            LOGGER.debug("end: invoke of WebDAVDatabase#updateWidthAndHeightByLocationAndUrl function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to update webdav video width and height`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#updateWidthAndHeightByLocationAndUrl function")
          })
      })
    })
  }

  public static updateLengthByLocationAndUrl(context: common.Context, length: number, location: string,
    url: string): Promise<void> {
    LOGGER.debug("start: invoke of WebDAVDatabase#updateLengthByLocationAndUrl function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#updateLengthByLocationAndUrl function")
          return;
        }
        store.update(
          {
            "VIDEO_LENGTH": length,
          },
          new relationalStore.RdbPredicates("WebDAVVideoLibrary")
            .equalTo("FILE_SOURCE", url)
            .equalTo("LOCATION", location)
        )
          .then((num: number) => {
            LOGGER.debug(`updated webdav video length`)
            LOGGER.debug(`update action affected ${num} rows of data`)
            LOGGER.debug("end: invoke of WebDAVDatabase#updateLengthByLocationAndUrl function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to update webdav video length`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#updateLengthByLocationAndUrl function")
          })
      })
    })
  }

  public static deleteWebdavByUrl(context: common.Context, url: string): Promise<void> {
    LOGGER.debug("start: invoke of WebDAVDatabase#deleteWebdavByUrl function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#deleteWebdavByUrl function")
          return;
        }

        store.delete(
          new relationalStore.RdbPredicates("WebDAVServers")
            .equalTo("SERVER_URL", url)
        )
          .then((num: number) => {
            LOGGER.debug(`deleted a webdav server`)
            LOGGER.debug(`delete action affected ${num} rows of data`)
            LOGGER.debug("end: invoke of WebDAVDatabase#deleteWebdavByUrl function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to delete webdav server`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#deleteWebdavByUrl function")
          })
      })
    })
  }

  public static deleteVideoByLocationAndUrl(context: common.Context, location: string, url: string): Promise<void> {
    // WebDAV 得使用文件位置和服务器 url 来进行双重判断
    LOGGER.debug("start: invoke of WebDAVDatabase#deleteVideoByLocationAndUrl function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          LOGGER.error(`failed to get RdbStore`, {
            error: err
          })
          LOGGER.debug("end: invoke of WebDAVDatabase#deleteVideoByLocationAndUrl function")
          return;
        }

        store.delete(
          new relationalStore.RdbPredicates("WebDAVVideoLibrary")
            .equalTo("FILE_SOURCE", url)
            .equalTo("LOCATION", location)
        )
          .then((num: number) => {
            LOGGER.debug(`deleted a webdav video`)
            LOGGER.debug(`delete action affected ${num} rows of data`)
            LOGGER.debug("end: invoke of WebDAVDatabase#deleteVideoByLocationAndUrl function")
            resultReturner()
          })
          .catch((err: BusinessError) => {
            LOGGER.error(`failed to delete webdav video`, {
              error: err
            })
            LOGGER.debug("end: invoke of WebDAVDatabase#deleteVideoByLocationAndUrl function")
          })
      })
    })
  }
}
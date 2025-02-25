import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { BusinessError } from '@kit.BasicServicesKit';
import { WebDAVAuthorization } from '../entity/WebDAVEntity';
import { WebDAVVideoSource } from '../entity/VideoEntity';
import { image } from '@kit.ImageKit';
import { pixelMapToArrayBuffer } from '../util/ImageUtil';

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
    relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
      if (err) {
        hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
        return;
      }
      if (store.version === 0) {
        store.executeSql(WebDAVDatabase.SQL_CREATE_WEBDAV_SERVER_TABLE)
        store.executeSql(WebDAVDatabase.SQL_CREATE_WEVDAV_VIDEO_LIBRARY_TABLE)
        store.version = 1
      }

      hilog.debug(0x0, "database", "created webdav database")
    })
  }


  public static addVideo(context: common.Context, webdavUri: string, location: string,
    name: string): Promise<WebDAVVideoSource> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        context.resourceManager.getMediaContent($rawfile("empty_video_cover.png"))
          .then((coverData) => {
            let imageSource = image.createImageSource(coverData)
            if (imageSource == undefined) {
              console.error(`image source is undefined`)
              return
            }
            let pixelMap = imageSource.createPixelMapSync()
            if (pixelMap == undefined) {
              console.error(`pixel map is undefined`)
              return
            }
            pixelMapToArrayBuffer(pixelMap)
              .then((buffer) => {
                store.insert(
                  "WebDAVVideoLibrary",
                  {
                    "LOCATION": location,
                    "TITLE": name,
                    "ADDED_TIME": Date.now(),
                    "FILE_SOURCE": webdavUri,
                    "VIDEO_LENGTH": -1,
                    "VIDEO_WIDTH": -1,
                    "VIDEO_HEIGHT": -1,
                    "PLAYED_LENGTH": -1,
                    "VIDEO_COVER": new Uint8Array(buffer)
                  }
                ).then(() => {
                  resultReturner(new WebDAVVideoSource(
                    location,
                    name,
                    Date.now(),
                    -1,
                    -1,
                    -1,
                    -1,
                    buffer,
                    webdavUri
                  ))
                })
              })
          })
      })
    })
  }

  public static addWebDAV(context: common.Context, authorization: WebDAVAuthorization): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
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
        ).then(() => {
          resultReturner()
        })
      })
    })
  }

  public static unsafeListWebDAV(context: common.Context): Promise<Array<WebDAVAuthorization>> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        store.query(new relationalStore.RdbPredicates("WebDAVServers"), async (err: BusinessError, resultSet) => {
          if (err) {
            hilog.error(0x2, "database", `Failed to query data. Code:${err.code}, message:${err.message}`)
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            console.error("there are no data in database")
            resultReturner(new Array())
          } else {
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

            resultReturner(webdavs)
          }
        })
      })
    })
  }

  public static unsafeListVideos(context: common.Context): Promise<Array<WebDAVVideoSource>> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        store.query(new relationalStore.RdbPredicates("WebDAVVideoLibrary"), async (err: BusinessError, resultSet) => {
          if (err) {
            hilog.error(0x2, "database", `Failed to query data. Code:${err.code}, message:${err.message}`)
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            console.error("there are no data in database")
            resultReturner(new Array())
          } else {
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

            resultReturner(videos)
          }
        })
      })
    })
  }

  public static deleteByUrl(context: common.Context, url: string): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        store.delete(
          new relationalStore.RdbPredicates("WebDAVServers")
            .equalTo("SERVER_URL", url)
        )
          .then((num: number) => {
            resultReturner()
          })
      })
    })
  }

  public static deleteVideoByLocationAndUrl(context: common.Context, location: string, url: string): Promise<void> {
    // WebDAV 得使用文件位置和服务器 url 来进行双重判断
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, WebDAVDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        store.delete(
          new relationalStore.RdbPredicates("WebDAVVideoLibrary")
            .equalTo("FILE_SOURCE", url)
            .equalTo("LOCATIOn", location)
        )
          .then((num: number) => {
            resultReturner()
          })
      })
    })
  }
}
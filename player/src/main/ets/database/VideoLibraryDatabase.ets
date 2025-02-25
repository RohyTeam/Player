import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { fileIo, fileShare, hash } from '@kit.CoreFileKit';
import { FileUtil } from '@pura/harmony-utils';
import { VideoEntity } from '../entity/VideoEntity';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { pixelMapToArrayBuffer } from '../util/ImageUtil';

export class VideoLibraryDatabase {
  private static SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS VideoLibrary (' +
    'LOCATION TEXT,' +
    'TITLE TEXT,' +
    'ADDED_TIME INTEGER,' +
    'FILE_HASH TEXT,' +
    'VIDEO_COVER BLOB,' +
    'VIDEO_LENGTH INTEGER,' +
    'VIDEO_WIDTH INTEGER,' +
    'VIDEO_HEIGHT INTEGER,' +
    'PLAYED_LENGTH INTEGER,' +
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
      /*

            store.version = 1001;
            if (store.version == 1001) {
              store.executeSync("DROP TABLE VideoLibrary;")
              store.executeSync(VideoLibraryDatabase.SQL_CREATE_TABLE)
              store.version = 3
            }
      */

      if (store.version === 0) {
        store.executeSql(VideoLibraryDatabase.SQL_CREATE_TABLE)
        store.version = 1
      } else if (store.version == 1) {
        store.executeSql('ALTER TABLE VideoLibrary ADD COLUMN FILE_SOURCE TEXT DEFAULT `LOCAL_FILE`;');
        store.version = 2
      } else if (store.version == 2) {
        store.executeSync('ALTER TABLE VideoLibrary ADD COLUMN VIDEO_COVER BLOB;');
        store.executeSync('ALTER TABLE VideoLibrary ADD COLUMN VIDEO_LENGTH INTEGER DEFAULT -1;');
        store.executeSync('ALTER TABLE VideoLibrary ADD COLUMN VIDEO_WIDTH INTEGER DEFAULT -1;');
        store.executeSync('ALTER TABLE VideoLibrary ADD COLUMN VIDEO_HEIGHT INTEGER DEFAULT -1;');
        store.version = 3
      } else if (store.version == 3) {
        store.executeSync('ALTER TABLE VideoLibrary ADD COLUMN PLAYED_LENGTH INTEGER DEFAULT -1;');
        store.version = 4
      }

      hilog.debug(0x0, "database", "created video database")
    })
  }

  public static tryFetchByHash(context: common.Context, hashValue: string): Promise<VideoEntity | undefined> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        store.query(new relationalStore.RdbPredicates("VideoLibrary")
          .equalTo("FILE_HASH", hashValue), async (err: BusinessError, resultSet) => {
          if (err) {
            hilog.error(0x2, "database", `Failed to query data. Code:${err.code}, message:${err.message}`)
            resultReturner(undefined)
            return
          }
          if (resultSet.rowCount == 0) {
            console.error("there are no data in database")
            resultReturner(undefined)
          } else {
            resultSet.goToFirstRow()
            let video: VideoEntity = {
              uri: resultSet.getString(resultSet.getColumnIndex("LOCATION")),
              title: resultSet.getString(resultSet.getColumnIndex("TITLE")),
              addedTime: resultSet.getLong(resultSet.getColumnIndex("ADDED_TIME")),
              hash: resultSet.getString(resultSet.getColumnIndex("FILE_HASH")),
              fileSource: resultSet.getString(resultSet.getColumnIndex("FILE_SOURCE")).toLowerCase(),
              played: resultSet.getLong(resultSet.getColumnIndex("PLAYED_LENGTH")),
              length: resultSet.getLong(resultSet.getColumnIndex("VIDEO_LENGTH")),
              width: resultSet.getLong(resultSet.getColumnIndex("VIDEO_WIDTH")),
              height: resultSet.getLong(resultSet.getColumnIndex("VIDEO_HEIGHT")),
              cover: resultSet.getBlob(resultSet.getColumnIndex("VIDEO_COVER")).buffer as ArrayBuffer
            }
            resultReturner(video)
          }
        })
      })
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
                fileIo.open(uri)
                  .then((file) => {
                    media.createAVImageGenerator().then((avImageGenerator: media.AVImageGenerator) => {
                      avImageGenerator.fdSrc = { fd: file.fd }
                      let timeUs = 0
                      let queryOption = media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC
                      let param: media.PixelMapParams = {
                        width: 720,
                        height: 540
                      }
                      avImageGenerator.fetchFrameByTime(timeUs, queryOption, param)
                        .then((pixelMap) => {
                          pixelMapToArrayBuffer(pixelMap)
                            .then((buffer) => {
                              avImageGenerator.release()

                              media.createAVMetadataExtractor()
                                .then((avMetadataExtractor: media.AVMetadataExtractor) => {
                                  avMetadataExtractor.fdSrc = { fd: file.fd }
                                  avMetadataExtractor.fetchMetadata()
                                    .then((metadata) => {
                                      let length = parseInt(metadata.duration!) || 0
                                      let width = parseInt(metadata.videoWidth!) || 0
                                      let height = parseInt(metadata.videoHeight!) || 0
                                      store.insert(
                                        "VideoLibrary",
                                        {
                                          "LOCATION": uri,
                                          "TITLE": FileUtil.getFileName(uri),
                                          "ADDED_TIME": Date.now(),
                                          "FILE_HASH": hashValue,
                                          "FILE_SOURCE": "LOCAL_FILE",
                                          "VIDEO_LENGTH": length,
                                          "VIDEO_WIDTH": width,
                                          "VIDEO_HEIGHT": height,
                                          "PLAYED_LENGTH": -1,
                                          "VIDEO_COVER": new Uint8Array(buffer)
                                        }
                                      ).then(() => {
                                        avMetadataExtractor.release()
                                        resultReturner({
                                          uri: uri,
                                          title: FileUtil.getFileName(uri),
                                          addedTime: Date.now(),
                                          hash: hashValue,
                                          fileSource: "local_file",
                                          played: -1,
                                          length: length,
                                          width: width,
                                          height: height,
                                          cover: buffer
                                        })
                                      })
                                        .catch((error: BusinessError) => {
                                          console.error(`error occurs when processing data (inserting to library), code: ${error.code}, message: ${error.message}`)
                                        })
                                    })
                                    .catch((error: BusinessError) => {
                                      console.error(`error occurs when processing data (getting metadata), code: ${error.code}, message: ${error.message}`)
                                    })
                                })
                                .catch((error: BusinessError) => {
                                  console.error(`error occurs when processing data (initing metadata fetcher), code: ${error.code}, message: ${error.message}`)
                                })
                            })
                            .catch((error: BusinessError) => {
                              console.error(`error occurs when processing data (converting cover data), code: ${error.code}, message: ${error.message}`)
                            })
                        })
                        .catch((error: BusinessError) => {
                          console.error(`error occurs when processing data (generating cover), code: ${error.code}, message: ${error.message}`)
                        })
                    })
                      .catch((error: BusinessError) => {
                        console.error(`error occurs when processing data (initing cover generator), code: ${error.code}, message: ${error.message}`)
                      })
                  })
                  .catch((error: BusinessError) => {
                    console.error(`error occurs when processing data (opening), code: ${error.code}, message: ${error.message}`)
                  })
              })
              .catch((error: BusinessError) => {
                console.error(`error occurs when processing data (hashing), code: ${error.code}, message: ${error.message}`)
              })
          })
          .catch((error: BusinessError) => {
            console.error(`error occurs when processing data, code: ${error.code}, message: ${error.message}`)
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

        fileIo.open(uri)
          .then((file) => {
            media.createAVImageGenerator().then((avImageGenerator: media.AVImageGenerator) => {
              avImageGenerator.fdSrc = { fd: file.fd }
              let timeUs = 0
              let queryOption = media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC
              let param: media.PixelMapParams = {
                width: 720,
                height: 540
              }
              avImageGenerator.fetchFrameByTime(timeUs, queryOption, param)
                .then((pixelMap) => {
                  pixelMapToArrayBuffer(pixelMap)
                    .then((buffer) => {
                      avImageGenerator.release()

                      media.createAVMetadataExtractor().then((avMetadataExtractor: media.AVMetadataExtractor) => {
                        avMetadataExtractor.fdSrc = { fd: file.fd }
                        avMetadataExtractor.fetchMetadata()
                          .then((metadata) => {
                            let length = parseInt(metadata.duration!) || 0
                            let width = parseInt(metadata.videoWidth!) || 0
                            let height = parseInt(metadata.videoHeight!) || 0
                            store.insert(
                              "VideoLibrary",
                              {
                                "LOCATION": uri,
                                "TITLE": displayName,
                                "ADDED_TIME": Date.now(),
                                "FILE_HASH": photoHash,
                                "FILE_SOURCE": "PHOTOS",
                                "VIDEO_LENGTH": length,
                                "VIDEO_WIDTH": width,
                                "VIDEO_HEIGHT": height,
                                "PLAYED_LENGTH": -1,
                                "VIDEO_COVER": new Uint8Array(buffer)
                              }
                            ).then(() => {
                              avMetadataExtractor.release()
                              resultReturner({
                                uri: uri,
                                title: FileUtil.getFileName(uri),
                                addedTime: Date.now(),
                                hash: photoHash,
                                fileSource: "photos",
                                played: -1,
                                length: length,
                                width: width,
                                height: height,
                                cover: buffer
                              })
                            })
                          })
                      })
                    })
                })
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
                played: resultSet.getLong(resultSet.getColumnIndex("PLAYED_LENGTH")),
                length: resultSet.getLong(resultSet.getColumnIndex("VIDEO_LENGTH")),
                width: resultSet.getLong(resultSet.getColumnIndex("VIDEO_WIDTH")),
                height: resultSet.getLong(resultSet.getColumnIndex("VIDEO_HEIGHT")),
                cover: resultSet.getBlob(resultSet.getColumnIndex("VIDEO_COVER")).buffer as ArrayBuffer
              }
              videos.push(video)
            }

            resultReturner(videos)
          }
        })
      })
    })
  }

  public static deleteByHash(context: common.Context, uri: string, hashValue: string): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        fileShare.revokePermission([// 移除持久化授权，保护用户文件安全
          {
            uri: uri,
            operationMode: 0b1
          }
        ])

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

  public static updatePlayedByHash(context: common.Context, hashValue: string, played: number): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }
        store.update(
          {
            "PLAYED_LENGTH": played
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

  public static updateVersion3ByHash(context: common.Context, hashValue: string, uri: string): Promise<void> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          hilog.error(0x2, "database", `Failed to get RdbStore. Code:${err.code}, message:${err.message}`)
          return;
        }

        fileIo.open(uri)
          .then((file) => {
            media.createAVImageGenerator().then((avImageGenerator: media.AVImageGenerator) => {
              avImageGenerator.fdSrc = { fd: file.fd }
              let timeUs = 0
              let queryOption = media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC
              let param: media.PixelMapParams = {
                width: 720,
                height: 540
              }
              avImageGenerator.fetchFrameByTime(timeUs, queryOption, param)
                .then((pixelMap) => {
                  pixelMapToArrayBuffer(pixelMap)
                    .then((buffer) => {
                      avImageGenerator.release()

                      media.createAVMetadataExtractor().then((avMetadataExtractor: media.AVMetadataExtractor) => {
                        avMetadataExtractor.fdSrc = { fd: file.fd }
                        avMetadataExtractor.fetchMetadata()
                          .then((metadata) => {

                            store.update(
                              {
                                "VIDEO_LENGTH": parseInt(metadata.duration) || 0,
                                "VIDEO_WIDTH": parseInt(metadata.videoWidth) || 0,
                                "VIDEO_HEIGHT": parseInt(metadata.videoHeight) || 0,
                                "VIDEO_COVER": new Uint8Array(buffer)
                              },
                              new relationalStore.RdbPredicates("VideoLibrary")
                                .equalTo("FILE_HASH", hashValue)
                            )
                              .then((num: number) => {
                                avMetadataExtractor.release()
                                resultReturner()
                              })
                          })
                      })
                    })
                })
            })
          })
      })
    })
  }
}
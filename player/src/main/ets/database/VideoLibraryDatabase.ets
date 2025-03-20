import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import hilog from '@ohos.hilog';
import { fileIo, fileShare, hash } from '@kit.CoreFileKit';
import { FileUtil } from '@pura/harmony-utils';
import { FileVideoSource, LocalVideoSource, PhotosVideoSource } from '../entity/VideoEntity';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';
import { pixelMapToArrayBuffer } from '../util/ImageUtil';
import { Rlog } from '../log/Rlog';
import { videoLibraryDatabase_tryFetchCover } from '../util/DatabaseUtil';

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

  public static clearVideosFromPhotos(context: common.Context) {
    Rlog.debug("start: invoke of VideoLibraryDatabase#clearVideosFromPhotos function")
    relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
      if (err) {
        Rlog.error(`failed to get RdbStore`, {
          error: err,
          tag: 'VideoLibrary'
        })
        Rlog.debug("end: invoke of VideoLibraryDatabase#clearVideosFromPhotos function")
        return;
      }

      store.delete(
        new relationalStore.RdbPredicates("VideoLibrary")
          .equalTo("FILE_SOURCE", "PHOTOS")
      )
        .then((num: number) => {
          Rlog.debug(`deleted ${num} data`)
          Rlog.debug("end: invoke of VideoLibraryDatabase#clearVideosFromPhotos function")
        })
        .catch((err: BusinessError) => {
          Rlog.error(`failed to delete videos from video library`, {
            error: err,
            tag: 'VideoLibraryDatabase#clearVideosFromPhotos'
          })
          Rlog.debug("end: invoke of VideoLibraryDatabase#clearVideosFromPhotos function")
        })
    })
  }

  public static init(context: common.Context) {
    Rlog.debug("start: invoke of VideoLibraryDatabase#init function")
    relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
      if (err) {
        Rlog.error(`failed to get RdbStore`, {
          error: err,
          tag: 'VideoLibrary'
        })
        Rlog.debug("end: invoke of VideoLibraryDatabase#init function")
        return;
      }

      if (store.version === 0) {
        store.executeSql(VideoLibraryDatabase.SQL_CREATE_TABLE)
        store.version = 4 // TODO：记得每次更新数据库后修改这个版本号啊！别忘了把这个版本号设置为最新的！
        Rlog.debug(`initialized video library database`)
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
      } else {
        Rlog.debug(`video library database has already been initialized, nothing to do`)
      }

      Rlog.debug("end: invoke of VideoLibraryDatabase#init function")
    })
  }

  public static tryFetchByHash(context: common.Context, hashValue: string): Promise<LocalVideoSource | undefined> {
    Rlog.debug("start: invoke of VideoLibraryDatabase#tryFetchByHash function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          Rlog.error(`failed to get RdbStore`, {
            error: err
          })
          Rlog.debug("end: invoke of VideoLibraryDatabase#tryFetchByHash function")
          return;
        }

        store.query(new relationalStore.RdbPredicates("VideoLibrary")
          .equalTo("FILE_HASH", hashValue), async (err: BusinessError, resultSet) => {
          if (err) {
            Rlog.error(`failed to query data from video library`, {
              error: err,
              tag: 'VideoLibrary'
            })
            Rlog.debug("end: invoke of VideoLibraryDatabase#tryFetchByHash function")
            resultReturner(undefined)
            return
          }
          if (resultSet.rowCount == 0) {
            Rlog.debug(`there is not data in "VideoLibrary" table`)
            Rlog.debug("end: invoke of VideoLibraryDatabase#tryFetchByHash function")
            resultReturner(undefined)
          } else {
            resultSet.goToFirstRow()
            if (resultSet.getString(resultSet.getColumnIndex("FILE_SOURCE")).toLowerCase() == "local_file") {
              Rlog.debug("end: invoke of VideoLibraryDatabase#tryFetchByHash function")
              resultReturner(
                new FileVideoSource(
                  resultSet.getString(resultSet.getColumnIndex("LOCATION")),
                  resultSet.getString(resultSet.getColumnIndex("TITLE")),
                  resultSet.getLong(resultSet.getColumnIndex("ADDED_TIME")),
                  resultSet.getLong(resultSet.getColumnIndex("PLAYED_LENGTH")),
                  resultSet.getLong(resultSet.getColumnIndex("VIDEO_LENGTH")),
                  resultSet.getLong(resultSet.getColumnIndex("VIDEO_WIDTH")),
                  resultSet.getLong(resultSet.getColumnIndex("VIDEO_HEIGHT")),
                  resultSet.getBlob(resultSet.getColumnIndex("VIDEO_COVER")).buffer as ArrayBuffer,
                  resultSet.getString(resultSet.getColumnIndex("FILE_HASH"))
                )
              )
            } else {
              Rlog.debug("end: invoke of VideoLibraryDatabase#tryFetchByHash function")
              resultReturner(
                new PhotosVideoSource(
                  resultSet.getString(resultSet.getColumnIndex("LOCATION")),
                  resultSet.getString(resultSet.getColumnIndex("TITLE")),
                  resultSet.getLong(resultSet.getColumnIndex("ADDED_TIME")),
                  resultSet.getLong(resultSet.getColumnIndex("PLAYED_LENGTH")),
                  resultSet.getLong(resultSet.getColumnIndex("VIDEO_LENGTH")),
                  resultSet.getLong(resultSet.getColumnIndex("VIDEO_WIDTH")),
                  resultSet.getLong(resultSet.getColumnIndex("VIDEO_HEIGHT")),
                  resultSet.getBlob(resultSet.getColumnIndex("VIDEO_COVER")).buffer as ArrayBuffer,
                  resultSet.getString(resultSet.getColumnIndex("FILE_HASH"))
                )
              )
            }
          }
        })
      })
    })

  }

  public static addFromLocalFile(context: common.Context, uri: string): Promise<FileVideoSource> {
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
          Rlog.error(`failed to get RdbStore`, {
            error: err,
            tag: 'VideoLibrary'
          })
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
                    media.createAVMetadataExtractor()
                      .then((avMetadataExtractor: media.AVMetadataExtractor) => {
                        avMetadataExtractor.fdSrc = { fd: file.fd }

                        videoLibraryDatabase_tryFetchCover(context, file, avMetadataExtractor)
                          .then((pixelMap) => {
                            pixelMapToArrayBuffer(pixelMap)
                              .then((buffer) => {
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
                                      resultReturner(new FileVideoSource(
                                        uri,
                                        FileUtil.getFileName(uri),
                                        Date.now(),
                                        -1,
                                        length,
                                        width,
                                        height,
                                        buffer,
                                        hashValue
                                      ))
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
                                console.error(`error occurs when processing data (converting cover data), code: ${error.code}, message: ${error.message}`)
                              })
                          })
                      })
                      .catch((error: BusinessError) => {
                        console.error(`error occurs when processing data (initing metadata fetcher), code: ${error.code}, message: ${error.message}`)
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
    photoHash: string): Promise<PhotosVideoSource> {
    Rlog.debug("start: invoke of VideoLibraryDatabase#addFromPhotos function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
        Rlog.error(`failed to get RdbStore`, {
          error: err,
          tag: 'VideoLibrary'
        })
          return;
        }

        fileIo.open(uri)
          .then((file) => {
            Rlog.debug("opened video file")
            media.createAVImageGenerator()
              .then((avImageGenerator: media.AVImageGenerator) => {
                Rlog.debug("created av image generator")
              avImageGenerator.fdSrc = { fd: file.fd }
              let timeUs = 0
              let queryOption = media.AVImageQueryOptions.AV_IMAGE_QUERY_NEXT_SYNC
              let param: media.PixelMapParams = {
                width: 720,
                height: 540
              }
              avImageGenerator.fetchFrameByTime(timeUs, queryOption, param)
                .then((pixelMap) => {
                  Rlog.debug("frame fetched")
                  pixelMapToArrayBuffer(pixelMap)
                    .then((buffer) => {
                      Rlog.debug("converted pixelmap to array buffer")
                      avImageGenerator.release()
                      media.createAVMetadataExtractor()
                        .then((avMetadataExtractor: media.AVMetadataExtractor) => {
                          Rlog.debug("created av metadata extractor")
                        avMetadataExtractor.fdSrc = { fd: file.fd }
                        avMetadataExtractor.fetchMetadata()
                          .then((metadata) => {
                            Rlog.debug("fetched metadata")
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
                              Rlog.debug("data inserted")
                              avMetadataExtractor.release()
                              resultReturner(new PhotosVideoSource(
                                uri,
                                FileUtil.getFileName(uri),
                                Date.now(),
                                -1,
                                length,
                                width,
                                height,
                                buffer,
                                photoHash
                              ))
                            })
                              .catch((err: BusinessError) => {
                                Rlog.error(`error occurs when inserting data`, {
                                  error: err,
                                  tag: 'VideoLibraryDatabase#addFromPhotos'
                                })
                              })
                          })
                          .catch((err: BusinessError) => {
                            Rlog.error(`error occurs when executing AVMetadataExtractor#fetchMetadata`, {
                              error: err,
                              tag: 'VideoLibraryDatabase#addFromPhotos'
                            })
                          })
                      })
                        .catch((err: BusinessError) => {
                          Rlog.error(`error occurs when executing media#createAVMetadataExtractor`, {
                            error: err,
                            tag: 'VideoLibraryDatabase#addFromPhotos'
                          })
                        })
                    })
                    .catch((err: BusinessError) => {
                      Rlog.error(`error occurs when executing pixelMapToArrayBuffer`, {
                        error: err,
                        tag: 'VideoLibraryDatabase#addFromPhotos'
                      })
                    })
                })
                .catch((err: BusinessError) => {
                  Rlog.error(`error occurs when executing AVImageGenerator#fetchFrameByTime`, {
                    error: err,
                    tag: 'VideoLibraryDatabase#addFromPhotos'
                  })
                })
            })
              .catch((err: BusinessError) => {
                Rlog.error(`error occurs when executing media#createAVImageGenerator`, {
                  error: err,
                  tag: 'VideoLibraryDatabase#addFromPhotos'
                })
              })
          })
          .catch((err: BusinessError) => {
            Rlog.error(`error occurs when executing fileIo#open`, {
              error: err,
              tag: 'VideoLibraryDatabase#addFromPhotos'
            })
          })
      })
    })
  }

  public static unsafeList(context: common.Context): Promise<Array<LocalVideoSource>> {
    Rlog.debug("start: invoke of VideoLibraryDatabase#unsafeList function")
    return new Promise((resultReturner) => {
      relationalStore.getRdbStore(context, VideoLibraryDatabase.databaseConfig, (err, store) => {
        if (err) {
        Rlog.error(`failed to get RdbStore`, {
          error: err,
          tag: 'VideoLibrary'
        })
          return;
        }
        store.query(new relationalStore.RdbPredicates("VideoLibrary"), async (err: BusinessError, resultSet) => {
          if (err) {
            hilog.error(0x2, "database", `Failed to query data. Code:${err.code}, message:${err.message}`)
            Rlog.debug("end: invoke of VideoLibraryDatabase#unsafeList function")
            resultReturner(new Array())
            return
          }
          if (resultSet.rowCount == 0) {
            Rlog.debug(`there is not data in "VideoLibrary" table`)
            Rlog.debug("end: invoke of VideoLibraryDatabase#unsafeList function")
            resultReturner(new Array())
          } else {
            let videos = new Array<LocalVideoSource>()
            Rlog.debug(`queried ${resultSet.rowCount} data from "VideoLibrary" table`)

            while (resultSet.goToNextRow()) {
              if (resultSet.getString(resultSet.getColumnIndex("FILE_SOURCE")).toLowerCase() == "local_file") {
                Rlog.debug(`found a local file`)
                videos.push(
                  new FileVideoSource(
                    resultSet.getString(resultSet.getColumnIndex("LOCATION")),
                    resultSet.getString(resultSet.getColumnIndex("TITLE")),
                    resultSet.getLong(resultSet.getColumnIndex("ADDED_TIME")),
                    resultSet.getLong(resultSet.getColumnIndex("PLAYED_LENGTH")),
                    resultSet.getLong(resultSet.getColumnIndex("VIDEO_LENGTH")),
                    resultSet.getLong(resultSet.getColumnIndex("VIDEO_WIDTH")),
                    resultSet.getLong(resultSet.getColumnIndex("VIDEO_HEIGHT")),
                    resultSet.getBlob(resultSet.getColumnIndex("VIDEO_COVER")).buffer as ArrayBuffer,
                    resultSet.getString(resultSet.getColumnIndex("FILE_HASH"))
                  )
                )
              } else {
                Rlog.debug(`found a photos file`)
                videos.push(
                  new PhotosVideoSource(
                    resultSet.getString(resultSet.getColumnIndex("LOCATION")),
                    resultSet.getString(resultSet.getColumnIndex("TITLE")),
                    resultSet.getLong(resultSet.getColumnIndex("ADDED_TIME")),
                    resultSet.getLong(resultSet.getColumnIndex("PLAYED_LENGTH")),
                    resultSet.getLong(resultSet.getColumnIndex("VIDEO_LENGTH")),
                    resultSet.getLong(resultSet.getColumnIndex("VIDEO_WIDTH")),
                    resultSet.getLong(resultSet.getColumnIndex("VIDEO_HEIGHT")),
                    resultSet.getBlob(resultSet.getColumnIndex("VIDEO_COVER")).buffer as ArrayBuffer,
                    resultSet.getString(resultSet.getColumnIndex("FILE_HASH"))
                  )
                )
              }
            }
            Rlog.debug(`unsafely listed ${videos.length} video${videos.length <= 1 ? "" : "s"} from local files database`)
            Rlog.debug("end: invoke of VideoLibraryDatabase#unsafeList function")
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
        Rlog.error(`failed to get RdbStore`, {
          error: err,
          tag: 'VideoLibrary'
        })
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
        Rlog.error(`failed to get RdbStore`, {
          error: err,
          tag: 'VideoLibrary'
        })
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
        Rlog.error(`failed to get RdbStore`, {
          error: err,
          tag: 'VideoLibrary'
        })
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
        Rlog.error(`failed to get RdbStore`, {
          error: err,
          tag: 'VideoLibrary'
        })
          return;
        }

        fileIo.open(uri)
          .then((file) => {
            // TODO: 想办法使用 ffmpeg 来获取视频的元数据
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
import { common } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Rlog } from '../log/Rlog';
import { fileIo } from '@kit.CoreFileKit';

export function videoLibraryDatabase_tryFetchCover(context: common.Context, file: fileIo.File,
  avMetadataExtractor: media.AVMetadataExtractor): Promise<PixelMap> {
  return new Promise((resultReturner) => {
    avMetadataExtractor.fetchAlbumCover()
      .then((pixelMap: PixelMap) => {
        let imageInfo = pixelMap.getImageInfoSync()
        pixelMap.scale(720 / imageInfo.size.width, 540 / imageInfo.size.height)
          .then(() => {
            resultReturner(pixelMap)
          })
      })
      .catch((err: BusinessError) => {
        Rlog.error(`failed to fetch album cover`, {
          tag: 'DatabaseUtil'
        })
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
              avImageGenerator.release()
              resultReturner(pixelMap)
            })
            .catch((error: BusinessError) => {
              console.error(`error occurs when processing data (generating cover), code: ${error.code}, message: ${error.message}`)
            })
        })
          .catch((error: BusinessError) => {
            console.error(`error occurs when processing data (initing cover generator), code: ${error.code}, message: ${error.message}`)
          })
      })
  })
}
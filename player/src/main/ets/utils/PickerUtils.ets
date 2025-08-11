import { ensureContext } from './AbilityUtils';
import { fileIo, picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';

export function pickSingleFolder(context: UIContext | Context): Promise<string | undefined> {
  return new Promise(async (resultReturner) => {
    let documentViewPicker = new picker.DocumentViewPicker(ensureContext(context));
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 1;
    documentSelectOptions.selectMode = picker.DocumentSelectMode.FOLDER

    let documentSelectResult = await documentViewPicker.select(documentSelectOptions)

    if (documentSelectResult.length > 0) {
      resultReturner(documentSelectResult[0])
    } else {
      resultReturner(undefined)
    }
  })
}

export function pickSingleVideoFile(context: UIContext | Context): Promise<string | undefined> {
  return new Promise(async (resultReturner) => {
    let documentViewPicker = new picker.DocumentViewPicker(ensureContext(context));
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = 1;
    documentSelectOptions.fileSuffixFilters = [
      '全部视频文件|.mp4,.mkv,.mov',
      'mp4 视频文件|.mp4',
      'mkv 视频文件|.mkv',
      'mov 视频文件|.mov'
    ];

    let documentSelectResult = await documentViewPicker.select(documentSelectOptions)

    if (documentSelectResult.length > 0) {
      resultReturner(documentSelectResult[0])
    } else {
      resultReturner(undefined)
    }
  })
}

export function pickVideoFiles(context: UIContext | Context, limit: number): Promise<string[]> {
  return new Promise(async (resultReturner) => {
    let documentViewPicker = new picker.DocumentViewPicker(ensureContext(context));
    const documentSelectOptions = new picker.DocumentSelectOptions();
    documentSelectOptions.maxSelectNumber = limit;
    documentSelectOptions.fileSuffixFilters = [
      '全部视频文件|.mp4,.mkv,.mov',
      'mp4 视频文件|.mp4',
      'mkv 视频文件|.mkv',
      'mov 视频文件|.mov'
    ];

    let documentSelectResult = await documentViewPicker.select(documentSelectOptions)

    resultReturner(documentSelectResult)
  })
}

export function pickPhotosVideoFiles(context: UIContext | Context,
  limit: number): Promise<photoAccessHelper.PhotoAsset[]> {
  return new Promise(async (resultReturner) => {
    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    photoSelectOptions.maxSelectNumber = limit;
    photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE
    photoSelectOptions.isPhotoTakingSupported = false // 临时拍一段视频导入进来？谁会这么干。。。

    let result = await photoPicker.select(photoSelectOptions)
    let accessor = photoAccessHelper.getPhotoAccessHelper(ensureContext(context))

    let photoAssets: photoAccessHelper.PhotoAsset[] = []

    for (let photoUri of result.photoUris) {
      let predicates = new dataSharePredicates.DataSharePredicates()
      predicates.equalTo("uri", photoUri)
      let assets = await accessor.getAssets({
        fetchColumns: [photoAccessHelper.PhotoKeys.TITLE],
        predicates: predicates
      })
      if (assets.getCount() <= 0) {
        continue
      }
      photoAssets.push(await assets.getFirstObject())
    }

    resultReturner(photoAssets)
  })
}

export function saveJpgFile(context: UIContext | Context, data: ArrayBuffer) {
  const documentSaveOptions = new picker.DocumentSaveOptions();
  documentSaveOptions.newFileNames = ["debug.jpg"];
  documentSaveOptions.fileSuffixChoices = ["JPEG|.jpg"];
  const documentViewPicker = new picker.DocumentViewPicker(ensureContext(context));
  documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
    let uri = documentSaveResult[0]
    fileIo.open(uri, fileIo.OpenMode.READ_WRITE)
      .then((file) => {
        fileIo.write(file.fd, data)
      })
  }).catch((err: BusinessError) => {
    console.error(`Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`);
  })
}
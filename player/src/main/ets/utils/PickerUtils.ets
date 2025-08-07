import { ability } from "./AbilityUtils";
import { fileIo, picker } from "@kit.CoreFileKit";
import { BusinessError } from "@kit.BasicServicesKit";

export function pickSingleVideoFile(context: UIContext | Context): Promise<string | undefined> {
  return new Promise(async (resultReturner) => {
    let documentViewPicker = new picker.DocumentViewPicker(ability(context).context);
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

export function saveJpgFile(context: UIContext | Context, data: ArrayBuffer) {
  const documentSaveOptions = new picker.DocumentSaveOptions();
  documentSaveOptions.newFileNames = ["debug.jpg"];
  documentSaveOptions.fileSuffixChoices = ["JPEG|.jpg"];
  const documentViewPicker = new picker.DocumentViewPicker(ability(context).context);
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
import { fileIo, picker } from '@kit.CoreFileKit';
import { ensureContext } from './AbilityUtils';
import { BusinessError } from '@kit.BasicServicesKit';

export class Files {
  public static saveDownload(context: UIContext | Context, path: string, data: ArrayBuffer | string) {
    while (path.startsWith("/")) {
      path = path.substring(1)
    }
    if (path == "") {
      return
    }

    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD
    const documentViewPicker = new picker.DocumentViewPicker(ensureContext(context));
    documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
      let uri = documentSaveResult[0]
      fileIo.open(`${uri}/${path}`, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
        .then((file) => {
          fileIo.write(file.fd, data)
        })
    }).catch((err: BusinessError) => {
      console.error(`Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`);
    })
  }
}
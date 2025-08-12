import { fileIo, fileUri, picker } from '@kit.CoreFileKit';
import { ensureContext, superContext } from './AbilityUtils';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

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

export function openOrCreateFileInFiles(name: string): fileIo.File {
  return fileIo.openSync(`${superContext().filesDir}/${name}`, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
}

export function readTextInFiles(name: string): string {
  return fileIo.readTextSync(new fileUri.FileUri(`${superContext().filesDir}/${name}`).path)
}

export function readBufferInFiles(name: string): ArrayBuffer {
  let file = openOrCreateFileInFiles(name)
  let arrayBuffer = new ArrayBuffer(fileIo.statSync(file.fd).size)
  fileIo.readSync(file.fd, arrayBuffer)
  fileIo.closeSync(file)
  return arrayBuffer
}

export function existsInFiles(name: string): boolean {
  return fileIo.accessSync(`${superContext().filesDir}/${name}`, fileIo.AccessModeType.EXIST)
}

export function deleteInFiles(name: string) {
  fileIo.unlinkSync(`${superContext().filesDir}/${name}`)
}
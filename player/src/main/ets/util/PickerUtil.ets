import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

export function saveDebugString(context: common.UIAbilityContext, data: string) {
  const documentSaveOptions = new picker.DocumentSaveOptions();
  documentSaveOptions.newFileNames = ["debug.json"];
  documentSaveOptions.fileSuffixChoices = ['JSON|.json'];
  const documentViewPicker = new picker.DocumentViewPicker(context);
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

export function saveDebugArrayBuffer(context: common.UIAbilityContext, data: ArrayBuffer) {
  const documentSaveOptions = new picker.DocumentSaveOptions();
  documentSaveOptions.newFileNames = ["debug.png"];
  documentSaveOptions.fileSuffixChoices = ['PNG|.png'];
  const documentViewPicker = new picker.DocumentViewPicker(context);
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
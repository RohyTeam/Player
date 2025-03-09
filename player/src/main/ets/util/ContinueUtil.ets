/**
 * 无论什么函数，只要跟流转有关系，都扔在这里
 */
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

export function copyFileToContinueDir(context: common.UIAbilityContext, fileUri: string,
  hashValue: string): Promise<void> {
  return new Promise((resultReturner) => {
    let tempFileUri = `${context.distributedFilesDir}/${hashValue}.vid`
    fileIo.open(tempFileUri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      .then((destFile) => {
        fileIo.open(fileUri)
          .then((srcFile) => {
            fileIo.copyFile(srcFile.fd, destFile.fd)
              .then(() => {
                fileIo.close(srcFile)
                fileIo.close(destFile)
                let result = fileIo.accessSync(tempFileUri, fileIo.AccessModeType.EXIST)
                resultReturner()
              })
              .catch((error: BusinessError) => {
                let err: BusinessError = error as BusinessError;
              });
          })
          .catch((error: BusinessError) => {
            let err: BusinessError = error as BusinessError;
          });
      })
      .catch((error: BusinessError) => {
        let err: BusinessError = error as BusinessError;
      });
  })
}

export function connectDevice(device: string): Promise<void> {
  let listeners: fileIo.DfsListeners = {
    onStatus: (networkId: string, status: number): void => {
    }
  }

  return new Promise((resultReturner) => {
    fileIo.connectDfs(device, listeners)
      .then(() => {
        resultReturner()
      })
      .catch((error: BusinessError) => {
        let err: BusinessError = error as BusinessError;
      });
  })
}

export function disconnectDevice(device: string): Promise<void> {
  return new Promise((resultReturner) => {
    fileIo.disconnectDfs(device)
      .then(() => {
        resultReturner()
      })
      .catch((error: BusinessError) => {
        let err: BusinessError = error as BusinessError;
      });
  })
}
/**
 * 无论什么函数，只要跟流转有关系，都扔在这里
 */
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { FileUtil } from '@pura/harmony-utils';

export function copyFileToContinueDir(context: common.UIAbilityContext, fileUri: string, hashValue: string): Promise<void> {
  return new Promise((resultReturner) => {
    console.error('building temp uri')
    let tempFileUri = `${context.distributedFilesDir}/${hashValue}.vid`

    console.error(`tempfile uri ${tempFileUri}`)

    console.error('trying accessing')
    fileIo.open(tempFileUri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      .then((destFile) => {
        fileIo.open(fileUri)
          .then((srcFile) => {
            console.error('try copying')
            fileIo.copyFile(srcFile.fd, destFile.fd)
              .then(() => {
                fileIo.close(srcFile)
                fileIo.close(destFile)
                console.error(`copied file`);
                let result = fileIo.accessSync(tempFileUri, fileIo.AccessModeType.EXIST)
                console.error(`exists? ${result}`)
                resultReturner()
              })
              .catch((error: BusinessError) => {
                let err: BusinessError = error as BusinessError;
                console.error(`Failed to copy files Code: ${err.code}, message: ${err.message}`);
              });
          })
          .catch((error: BusinessError) => {
            let err: BusinessError = error as BusinessError;
            console.error(`Failed to open src file Code: ${err.code}, message: ${err.message}`);
          });
      })
      .catch((error: BusinessError) => {
        let err: BusinessError = error as BusinessError;
        console.error(`Failed to open dest file Code: ${err.code}, message: ${err.message}`);
      });
  })
}

export function connectDevice(device: string): Promise<void> {
  let listeners: fileIo.DfsListeners = {
    onStatus: (networkId: string, status: number): void => {
      console.info('Failed to access public directory');
    }
  }

  return new Promise((resultReturner) => {
    fileIo.connectDfs(device, listeners)
      .then(() => {
        console.error("Success to connectDfs");
        resultReturner()
      })
      .catch((error: BusinessError) => {
        let err: BusinessError = error as BusinessError;
        console.error(`Failed to connectDfs Code: ${err.code}, message: ${err.message}`);
      });
  })
}

export function disconnectDevice(device: string): Promise<void> {
  return new Promise((resultReturner) => {
    fileIo.disconnectDfs(device)
      .then(() => {
        console.info("Success to disconnectDfs");
        resultReturner()
      })
      .catch((error: BusinessError) => {
        let err: BusinessError = error as BusinessError;
        console.error(`Failed to disconnectDfs Code: ${err.code}, message: ${err.message}`);
      });
  })
}
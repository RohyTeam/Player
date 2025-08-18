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

export function getPathInFiles(name: string, context?: Context): string {
  return new fileUri.FileUri(`${(context ?? superContext()).filesDir}/${name}`).path
}

export function listFolderInFiles(name: string, context?: Context): string[] {
  return fileIo.listFileSync(getPathInFiles(name, context), { recursion: false })
}

export function openOrCreateFileInFiles(name: string, context?: Context): fileIo.File {
  return fileIo.openSync(`${(context ?? superContext()).filesDir}/${name}`, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
}

export function mkdirsInFiles(name: string, context?: Context) {
  fileIo.mkdirSync(`${(context ?? superContext()).filesDir}/${name}`, true)
}

export function createFileInFiles(name: string, context?: Context) {
  let file = fileIo.openSync(`${(context ?? superContext()).filesDir}/${name}`, fileIo.OpenMode.CREATE)
  fileIo.closeSync(file.fd)
}

export function readTextInFiles(name: string, context?: Context): string {
  return fileIo.readTextSync(new fileUri.FileUri(`${(context ?? superContext()).filesDir}/${name}`).path)
}

export function readBufferInFiles(name: string, context?: Context): ArrayBuffer {
  let file = openOrCreateFileInFiles(name, context)
  let arrayBuffer = new ArrayBuffer(fileIo.statSync(file.fd).size)
  fileIo.readSync(file.fd, arrayBuffer)
  fileIo.closeSync(file)
  return arrayBuffer
}

export function existsInFiles(name: string, context?: Context): boolean {
  return fileIo.accessSync(`${(context ?? superContext()).filesDir}/${name}`, fileIo.AccessModeType.EXIST)
}

export function folderExistsInFiles(name: string, context?: Context): boolean {
  let exists = fileIo.accessSync(`${(context ?? superContext()).filesDir}/${name}`, fileIo.AccessModeType.EXIST)
  if (!exists)
    return false
  let file = fileIo.openSync(`${(context ?? superContext()).filesDir}/${name}`)
  let stat = fileIo.statSync(file.fd)
  let isDirectory = stat.isDirectory()
  fileIo.closeSync(file)
  return isDirectory
}

export function fileExistsInFiles(name: string, context?: Context): boolean {
  let exists = fileIo.accessSync(`${(context ?? superContext()).filesDir}/${name}`, fileIo.AccessModeType.EXIST)
  if (!exists)
    return false
  let file = fileIo.openSync(`${(context ?? superContext()).filesDir}/${name}`)
  let stat = fileIo.statSync(file.fd)
  let isFile = stat.isFile()
  fileIo.closeSync(file)
  return isFile
}

export function deleteInFiles(name: string, context?: Context) {
  fileIo.unlinkSync(`${(context ?? superContext()).filesDir}/${name}`)
}

export function getPathInTemp(name: string, context?: Context): string {
  return new fileUri.FileUri(`${(context ?? superContext()).tempDir}/${name}`).path
}

export function listFolderInTemp(name: string, context?: Context): string[] {
  return fileIo.listFileSync(getPathInTemp(name, context), { recursion: false })
}

export function openOrCreateFileInTemp(name: string, context?: Context): fileIo.File {
  return fileIo.openSync(`${(context ?? superContext()).tempDir}/${name}`, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
}

export function mkdirsInTemp(name: string, context?: Context) {
  fileIo.mkdirSync(`${(context ?? superContext()).tempDir}/${name}`, true)
}

export function createFileInTemp(name: string, context?: Context) {
  let file = fileIo.openSync(`${(context ?? superContext()).tempDir}/${name}`, fileIo.OpenMode.CREATE)
  fileIo.closeSync(file.fd)
}

export function readTextInTemp(name: string, context?: Context): string {
  return fileIo.readTextSync(new fileUri.FileUri(`${(context ?? superContext()).tempDir}/${name}`).path)
}

export function readBufferInTemp(name: string, context?: Context): ArrayBuffer {
  let file = openOrCreateFileInTemp(name, context)
  let arrayBuffer = new ArrayBuffer(fileIo.statSync(file.fd).size)
  fileIo.readSync(file.fd, arrayBuffer)
  fileIo.closeSync(file)
  return arrayBuffer
}

export function existsInTemp(name: string, context?: Context): boolean {
  return fileIo.accessSync(`${(context ?? superContext()).tempDir}/${name}`, fileIo.AccessModeType.EXIST)
}

export function folderExistsInTemp(name: string, context?: Context): boolean {
  let exists = fileIo.accessSync(`${(context ?? superContext()).tempDir}/${name}`, fileIo.AccessModeType.EXIST)
  if (!exists)
    return false
  let file = fileIo.openSync(`${(context ?? superContext()).tempDir}/${name}`)
  let stat = fileIo.statSync(file.fd)
  let isDirectory = stat.isDirectory()
  fileIo.closeSync(file)
  return isDirectory
}

export function fileExistsInTemp(name: string, context?: Context): boolean {
  let exists = fileIo.accessSync(`${(context ?? superContext()).tempDir}/${name}`, fileIo.AccessModeType.EXIST)
  if (!exists)
    return false
  let file = fileIo.openSync(`${(context ?? superContext()).tempDir}/${name}`)
  let stat = fileIo.statSync(file.fd)
  let isFile = stat.isFile()
  fileIo.closeSync(file)
  return isFile
}

export function deleteInTemp(name: string, context?: Context) {
  fileIo.unlinkSync(`${(context ?? superContext()).tempDir}/${name}`)
}

export function ensurePath(uriOrPath: string): string {
  return new fileUri.FileUri(uriOrPath).path
}

export function ensureUri(uriOrPath: string): string {
  return fileUri.getUriFromPath(ensurePath(uriOrPath))
}

export function fileName(uriOrPath: string): string {
  return new fileUri.FileUri(uriOrPath).name
}
import { superContext } from '../utils/AbilityUtils'
import { fileIo } from '@kit.CoreFileKit'
import { ensurePath } from '../utils/FileUtils'

export class FileSystem {
  private tempDir: string
  private filesDir: string

  constructor(tempDir: string, filesDir: string) {
    this.tempDir = tempDir
    this.filesDir = filesDir
  }

  getPathInFiles(name: string): string {
    return ensurePath(`${this.filesDir}/${name}`)
  }

  listFolderInFiles(name: string): string[] {
    return fileIo.listFileSync(this.getPathInFiles(name), { recursion: false })
  }

  openOrCreateFileInFiles(name: string): fileIo.File {
    return fileIo.openSync(`${this.filesDir}/${name}`, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
  }

  mkdirsInFiles(name: string) {
    fileIo.mkdirSync(`${this.filesDir}/${name}`, true)
  }

  createFileInFiles(name: string) {
    let file = fileIo.openSync(`${this.filesDir}/${name}`, fileIo.OpenMode.CREATE)
    fileIo.closeSync(file.fd)
  }

  readTextInFiles(name: string): string {
    return fileIo.readTextSync(ensurePath(`${this.filesDir}/${name}`))
  }

  readBufferInFiles(name: string): ArrayBuffer {
    let file = this.openOrCreateFileInFiles(name)
    let arrayBuffer = new ArrayBuffer(fileIo.statSync(file.fd).size)
    fileIo.readSync(file.fd, arrayBuffer)
    fileIo.closeSync(file)
    return arrayBuffer
  }

  writeBufferInFiles(name: string, buffer: ArrayBuffer | string) {
    let file = this.openOrCreateFileInFiles(name)
    fileIo.writeSync(file.fd, buffer)
    fileIo.closeSync(file)
  }

  existsInFiles(name: string): boolean {
    return fileIo.accessSync(`${this.filesDir}/${name}`, fileIo.AccessModeType.EXIST)
  }

  folderExistsInFiles(name: string): boolean {
    let exists = fileIo.accessSync(`${this.filesDir}/${name}`, fileIo.AccessModeType.EXIST)
    if (!exists) {
      return false
    }
    let file = fileIo.openSync(`${this.filesDir}/${name}`)
    let stat = fileIo.statSync(file.fd)
    let isDirectory = stat.isDirectory()
    fileIo.closeSync(file)
    return isDirectory
  }

  fileExistsInFiles(name: string): boolean {
    let exists = fileIo.accessSync(`${this.filesDir}/${name}`, fileIo.AccessModeType.EXIST)
    if (!exists) {
      return false
    }
    let file = fileIo.openSync(`${this.filesDir}/${name}`)
    let stat = fileIo.statSync(file.fd)
    let isFile = stat.isFile()
    fileIo.closeSync(file)
    return isFile
  }

  deleteInFiles(name: string, isdir: boolean) {
    if (isdir) {
      fileIo.rmdirSync(`${this.filesDir}/${name}`)
    } else {
      fileIo.unlinkSync(`${this.filesDir}/${name}`)
    }
  }

  getPathInTemp(name: string): string {
    return ensurePath(`${this.tempDir}/${name}`)
  }

  listFolderInTemp(name: string): string[] {
    return fileIo.listFileSync(this.getPathInTemp(name), { recursion: false })
  }

  openOrCreateFileInTemp(name: string): fileIo.File {
    return fileIo.openSync(`${this.tempDir}/${name}`, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
  }

  mkdirsInTemp(name: string) {
    fileIo.mkdirSync(`${this.tempDir}/${name}`, true)
  }

  createFileInTemp(name: string) {
    let file = fileIo.openSync(`${this.tempDir}/${name}`, fileIo.OpenMode.CREATE)
    fileIo.closeSync(file.fd)
  }

  readTextInTemp(name: string): string {
    return fileIo.readTextSync(ensurePath(`${this.tempDir}/${name}`))
  }

  readBufferInTemp(name: string): ArrayBuffer {
    let file = this.openOrCreateFileInTemp(name)
    let arrayBuffer = new ArrayBuffer(fileIo.statSync(file.fd).size)
    fileIo.readSync(file.fd, arrayBuffer)
    fileIo.closeSync(file)
    return arrayBuffer
  }

  writeBufferInTemp(name: string, buffer: ArrayBuffer | string) {
    let file = this.openOrCreateFileInTemp(name)
    fileIo.writeSync(file.fd, buffer)
    fileIo.closeSync(file)
  }

  existsInTemp(name: string): boolean {
    return fileIo.accessSync(`${this.tempDir}/${name}`, fileIo.AccessModeType.EXIST)
  }

  folderExistsInTemp(name: string): boolean {
    let exists = fileIo.accessSync(`${this.tempDir}/${name}`, fileIo.AccessModeType.EXIST)
    if (!exists) {
      return false
    }
    let file = fileIo.openSync(`${this.tempDir}/${name}`)
    let stat = fileIo.statSync(file.fd)
    let isDirectory = stat.isDirectory()
    fileIo.closeSync(file)
    return isDirectory
  }

  fileExistsInTemp(name: string): boolean {
    let exists = fileIo.accessSync(`${this.tempDir}/${name}`, fileIo.AccessModeType.EXIST)
    if (!exists) {
      return false
    }
    let file = fileIo.openSync(`${this.tempDir}/${name}`)
    let stat = fileIo.statSync(file.fd)
    let isFile = stat.isFile()
    fileIo.closeSync(file)
    return isFile
  }

  deleteInTemp(name: string, isdir: boolean) {
    if (isdir) {
      fileIo.rmdirSync(`${this.tempDir}/${name}`)
    } else {
      fileIo.unlinkSync(`${this.tempDir}/${name}`)
    }
  }
}

export function appFileSystem(): FileSystem {
  let context = superContext()
  return new FileSystem(context.tempDir, context.filesDir)
}
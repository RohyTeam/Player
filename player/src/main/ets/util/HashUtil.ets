import { fileIo, hash } from '@kit.CoreFileKit';

/**
 * FIXME: 注意，这个函数只是 hash 库不能用于对图库中文件进行哈希的解决方案，甚至会出现同一个文件哈希值不一样的情况，有待优化
 */
export function hashByFd(fd: number, algorithm: string): Promise<string> {
  return new Promise((resultReturner) => {
    let hasher = hash.createHash(algorithm)
    let buffer = new ArrayBuffer(4096)
    while (fileIo.readSync(fd, buffer) > 0) {
      hasher.update(buffer)
    }
    resultReturner(hasher.digest())
  })
}
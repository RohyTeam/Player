import { createClient } from '../lib/webdav_client/WebDAVClient'
import { Secrets } from '../Secrets'

// 用于测试，上传之后为空代码文件
export function runTest() {
  try {
    let client = createClient(Secrets.WEBDAV_URL, {
      username: Secrets.WEBDAV_USERNAME,
      password: Secrets.WEBDAV_PASSWORD
    })
    client.authenticate()
      .then((result) => {
        if (result) {
          console.error(`trying to list directory`)
          client.listDirectory("/动漫库/相合之物")
            .then((files) => {
              for (let file of files) {
                console.error(`webdav file, name: ${file.displayName}, path: ${file.path}`)
              }
            })
        } else {
          console.error(`failed to authenticate`)
        }
      })
  } catch (err) {
    console.error(`error occurs when testing: ${JSON.stringify(err)}`)
  }
}
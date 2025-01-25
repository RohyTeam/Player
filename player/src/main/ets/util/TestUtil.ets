import { createClient } from '../lib/webdav_client/WebDAVClient'

// 用于测试，上传之后为空代码文件
export function runTest() {
  try {

    let client = createClient("", {
      username: '',
      password: ''
    })
    client.authenticate()
      .then((result) => {
        if (result) {
          client.listDirectory("/")
        }
      })
  } catch (err) {
    console.error(`error occurs when testing: ${JSON.stringify(err)}`)
  }
}
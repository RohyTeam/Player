import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { JSON } from '@kit.ArkTS'
import { StrUtil } from '@pura/harmony-utils'
import { rcp } from '@kit.RemoteCommunicationKit'
import { parseFiles, WebDAVFile } from './WebDAVFileSystem'
import { Headers } from '../../entity/Headers'
import { WebDAVAuthorization } from '../../entity/WebDAVEntity'

export interface WebDAVFileStream {

  read(buffer: ArrayBuffer, length: number, pos?: number): Promise<number>;

}

export interface WebDAVClient {

  getAuthorizationResult(): boolean | undefined

  getDisplayName(): string

  authenticate(): Promise<boolean>

  authenticateFile(file: string): Promise<FileResult>

  listDirectory(path: string): Promise<Array<WebDAVFile>>

  accessStream(path: string): Promise<WebDAVFileStream | undefined> // undefined 代表不支持选择范围

}

export interface LoginOptions {

  username: string
  password: string

}

enum AuthenticateMethodType {

  Basic, Digest

}

interface AuthenticateMethod {

  type: AuthenticateMethodType

  use(uri: string): Promise<string>

}

class WebDAVFileStreamImpl implements WebDAVFileStream {
  uri: string
  token: string
  size: number

  constructor(
    uri: string,
    token: string,
    size: number
  ) {
    this.uri = uri
    this.token = token
    this.size = size
  }

  read(buffer: ArrayBuffer, length: number, pos?: number | undefined): Promise<number> {
    return new Promise((resultReturner) => {
      let httpRequest = http.createHttp()
      let from = pos || 0
      let to = Math.min(from + length, this.size) - 1 // 右边是包含的，减一位
      if (to < from) {
        resultReturner(-1)
      } else {
        httpRequest.request(
          this.uri,
          {
            method: http.RequestMethod.HEAD,
            header: {
              'authorization': this.token,
              'range': `bytes=${from}-${to}`
            }
          },
          (err: BusinessError, response: http.HttpResponse) => {
            if (!err) {
              let result = response.result as ArrayBuffer
              httpRequest.destroy();
              // TODO，将 result 数据写入 buffer
              resultReturner(result.byteLength)
            } else {
              console.error(`error occurs when getting file stream: ${JSON.stringify(err)}, ${err.message}`)
              httpRequest.destroy();
              resultReturner(-1)
            }
          }
        )
      }
    })
  }
}

class BasicAuthenticateMethod implements AuthenticateMethod {
  type: AuthenticateMethodType = AuthenticateMethodType.Basic
  private token: string

  constructor(username: string, password: string) {
    this.token = StrUtil.strToBase64(`${username}:${password}`)
  }

  use(uri: string): Promise<string> {
    return new Promise((resultReturner) => {
      resultReturner(`Basic ${this.token}`)
    })
  }
}

class DigestAuthenticateMethod implements AuthenticateMethod {
  type: AuthenticateMethodType = AuthenticateMethodType.Digest
  private username: string
  private password: string

  constructor(username: string, password: string) {
    this.username = username
    this.password = password
  }

  use(uri: string): Promise<string> {
    return new Promise((resultReturner) => {
      let session = rcp.createSession()
      // TODO
    })
  }
}

export interface Unauthorized {}

export interface FileResult {

  url: string
  headers: Headers

}

type JsonValue = string | number | boolean | Record<string, object>

@Observed
class WebDAVClientImpl implements WebDAVClient {
  private displayName: string
  private serverUri: string
  private options: LoginOptions
  private authenticateResult: boolean | undefined = undefined
  private authenticateMethod: AuthenticateMethod | undefined = undefined

  constructor(displayName: string, serverUri: string, options: LoginOptions) {
    this.displayName = displayName
    this.serverUri = serverUri
    if (this.serverUri.endsWith("/")) {
      this.serverUri = this.serverUri.substring(0, this.serverUri.length - 1)
    }
    this.options = options
  }

  accessStream(file: string): Promise<WebDAVFileStream | undefined> {
    return new Promise((resultReturner) => {
      if (!file.startsWith("/")) {
        file = `/${file}`
      }
      console.error(`ready to authenticate file`)
      let requestUri = `${this.serverUri}${file}`
      console.error(`request uri is ${requestUri}`)
      requestUri = encodeURI(requestUri)
      this.authenticateMethod?.use(requestUri)
        .then((token) => {
          console.error(`token good`)

          let httpRequest = http.createHttp()
          httpRequest.request(
            requestUri,
            {
              method: http.RequestMethod.HEAD,
              header: {
                'authorization': token
              }
            },
            (err: BusinessError, response: http.HttpResponse) => {
              if (!err) {
                console.error(`response status code is ${response.responseCode}`)
                if (response.header['accept-ranges'] == undefined) {
                  resultReturner(undefined)
                } else {
                  let size = parseInt(response.header['content-length']) || -1
                  if (size == -1) {
                    resultReturner(undefined)
                  } else {
                    if (response.header['accept-ranges'] == 'bytes') {
                      resultReturner(
                        new WebDAVFileStreamImpl(
                          requestUri,
                          token,
                          size
                        )
                      )
                    } else {
                      resultReturner(undefined)
                    }
                  }
                }
                httpRequest.destroy();
              } else {
                console.error(`error occurs when getting file stream: ${JSON.stringify(err)}, ${err.message}`)
                httpRequest.destroy();
                resultReturner(undefined)
              }
            }
          )
        })
    })
  }

  getAuthorizationResult(): boolean | undefined {
    return this.authenticateResult
  }

  getDisplayName(): string {
    return this.displayName
  }

  authenticateFile(file: string): Promise<FileResult> {
    return new Promise((resultReturner) => {
      if (!file.startsWith("/")) {
        file = `/${file}`
      }
      console.error(`ready to authenticate file`)
      let requestUri = `${this.serverUri}${file}`
      console.error(`request uri is ${requestUri}`)
      requestUri = encodeURI(requestUri)
      this.authenticateMethod?.use(requestUri)
        .then((token) => {
          console.error(`token good`)
          resultReturner({
            url: requestUri,
            headers: {
              headers: {
                "authorization": token
              }
            }
          })
        })
    })
  }

  listDirectory(path: string): Promise<WebDAVFile[]> {
    return new Promise((resultReturner) => {
      if (this.authenticateMethod != undefined) {
        if (!path.startsWith("/")) {
          path = `/${path}`
        }
        let requestUri = `${this.serverUri}${path}`
        this.authenticateMethod.use(requestUri)
          .then(async (token) => {
            let session = rcp.createSession()
            let headers: rcp.RequestHeaders = {
              'authorization': token,
              'depth': '1'
            }
            let request = new rcp.Request(
              requestUri,
              'PROPFIND',
              headers,
              ''
            )
            session.fetch(request)
              .then((response) => {
                if (response.statusCode == 207 && response.body != undefined) {
                  resultReturner(parseFiles(path, response.body))
                } else {
                  resultReturner([])
                }
              })
              .catch((error: BusinessError) => {
                console.error(`error occurs when list directory: ${JSON.stringify(error)}, ${error.message}`)
                resultReturner([])
              })
          })
          .catch((error: Error) => {
            console.error(`error occurs when use authentication: ${JSON.stringify(error)}, ${error.message}`)
            resultReturner([])
          })
      } else {
        console.error(`error occurs when list directory: not authorized`)
        resultReturner([])
      }
    })
  }

  private authTest(): Promise<boolean> {
    return new Promise((resultReturner) => {
      if (this.authenticateMethod != undefined) {
        this.authenticateMethod.use(this.serverUri)
          .then((token) => {
            let request = http.createHttp()
            request.request(this.serverUri, {
              header: {
                'authorization': token
              }
            })
              .then((testResponse: http.HttpResponse) => {
                if (testResponse.responseCode == 405) {
                  resultReturner(true)
                } else {
                  resultReturner(false)
                }
              })
              .catch((error: BusinessError) => {
                console.error(`error occurs when testing authorization: ${JSON.stringify(error)}`)
                resultReturner(false)
              })
          })
      } else {
        resultReturner(false)
      }
    })
  }

  authenticate(): Promise<boolean> {
    return new Promise((resultReturner) => {
      if (this.authenticateMethod != undefined) {
        resultReturner(true)
      }
      let methodTestRequest = http.createHttp()
      methodTestRequest.request(this.serverUri)
        .then((methodTestResponse: http.HttpResponse) => {
          if (methodTestResponse.responseCode == 401) {
            let headers = methodTestResponse.header as Record<string, JsonValue>
            if (JSON.has(headers, 'www-authenticate')) {
              let authenticateMethod: string = headers['www-authenticate'] as string
              console.error(`authenticate method is ${authenticateMethod}`)
              if (authenticateMethod.startsWith('Digest')) {
                // TODO: digest support
                // this.authenticateMethod = new DigestAuthenticateMethod(this.options.username, this.options.password)
              } else if (authenticateMethod.startsWith("Basic")) {
                this.authenticateMethod = new BasicAuthenticateMethod(this.options.username, this.options.password)
              }
              this.authTest()
                .then((result) => {
                  if (result) {
                    this.authenticateResult = true
                  } else {
                    this.authenticateResult = false
                  }
                  resultReturner(result)
                })
                .catch((error: BusinessError) => {
                  console.error(`error occurs when test authorization after getting method: ${JSON.stringify(error)}`)
                  this.authenticateResult = false
                  resultReturner(false)
                })
            } else {
              resultReturner(false)
            }
          } else {
            resultReturner(false)
          }
        })
        .catch((error: BusinessError) => {
          console.error(`error occurs when testing method: ${JSON.stringify(error)}`)
          this.authenticateResult = false
          resultReturner(false)
        })
    })
  }
}

export function createClient(displayName: string, serverUri: string, options: LoginOptions): WebDAVClient {
  return new WebDAVClientImpl(displayName, serverUri, options)
}

export function createClientByData(webdav: WebDAVAuthorization): WebDAVClient {
  return new WebDAVClientImpl(webdav.displayName, webdav.url, webdav.account)
}
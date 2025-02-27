import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { JSON } from '@kit.ArkTS'
import { StrUtil } from '@pura/harmony-utils'
import { rcp } from '@kit.RemoteCommunicationKit'
import { parseFiles, WebDAVFile } from './WebDAVFileSystem'
import { Headers } from '../../entity/Headers'
import { WebDAVAuthorization } from '../../entity/WebDAVEntity'

export interface WebDAVClient {

  getAuthorizationResult(): boolean | undefined

  getDisplayName(): string

  authenticate(): Promise<boolean>

  authenticateFile(file: string): Promise<FileResult>

  listDirectory(path: string): Promise<Array<WebDAVFile>>

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
          /*let httpRequest = http.createHttp()
          httpRequest.request(
              requestUri,
              {
                method: http.RequestMethod.GET,
                header: {
                  'authorization': token
                }
              },
              (err: BusinessError, response: http.HttpResponse) => {
                if (!err) {
                  console.error(`response status code is ${response.responseCode}`)
                  if (response.responseCode == 200) {
                    resultReturner({
                      url: requestUri,
                      headers: {
                        headers: {
                          "authorization": token
                        }
                      }
                    })
                  } else if (response.responseCode == 302) {
                    resultReturner({
                      url: response.header['location']!,
                      headers: {
                        headers: {
                          "authorization": token
                        }
                      }
                    })
                  }

                  httpRequest.destroy();
                } else {
                  console.error(`error occurs when accessing file: ${JSON.stringify(err)}, ${err.message}`)
                  httpRequest.destroy();
                }
              }
            )*/
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
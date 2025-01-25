import { http } from "@kit.NetworkKit"
import { BusinessError } from "@kit.BasicServicesKit"
import { JSON } from "@kit.ArkTS"
import { StrUtil } from "@pura/harmony-utils"

export interface WebDAVFile {

  name: string
  path: string

}

export interface WebDAVClient {

  authenticate(): Promise<boolean>

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

export interface Unauthorized {}

type JsonValue = string | number | boolean | Record<string, object>

class WebDAVClientImpl implements WebDAVClient {

  private serverUri: string
  private options: LoginOptions

  private authenticateResult: boolean | undefined = undefined
  private authenticateMethod: AuthenticateMethod | undefined = undefined

  constructor(serverUri: string, options: LoginOptions) {
    this.serverUri = serverUri
    if (this.serverUri.endsWith("/")) {
      this.serverUri = this.serverUri.substring(0, this.serverUri.length - 1)
    }
    this.options = options
  }

  listDirectory(path: string): Promise<WebDAVFile[]> {
    return new Promise((resultReturner) => {
      if (this.authenticateMethod != undefined) {
        if (!path.startsWith("/")) {
          path = `/${path}`
        }
        let requestUri = `${this.serverUri}${path}`
        this.authenticateMethod.use(requestUri)
          .then((token) => {
            let request = http.createHttp()
            request.request(requestUri, {
              method: http.RequestMethod.HEAD,
              header: {
                'accept': 'text/plain,application/xml',
                'authorization': token,
                'depth': 1
              }
            })
              .then((listResponse: http.HttpResponse) => {
                console.error(`list directory response: ${typeof listResponse.result}`)
              })
              .catch((error: BusinessError) => {
                console.error(`error occurs when listing directory: ${JSON.stringify(error)}`)
                resultReturner([])
              })
          })
      } else {
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
      let methodTestRequest = http.createHttp()
      methodTestRequest.request(this.serverUri)
        .then((methodTestResponse: http.HttpResponse) => {
          if (methodTestResponse.responseCode == 401) {
            let headers = methodTestResponse.header as Record<string, JsonValue>
            if (JSON.has(headers, 'www-authenticate')) {
              let authenticateMethod: string = headers['www-authenticate'] as string
              console.error(`authenticate method is ${authenticateMethod}`)
              if (authenticateMethod.startsWith('Digest')) {

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

export function createClient(serverUri: string, options: LoginOptions): WebDAVClient {
  return new WebDAVClientImpl(serverUri, options)
}
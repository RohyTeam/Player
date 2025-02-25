import { LoginOptions } from '../lib/webdav_client/WebDAVClient'

export interface WebDAVAuthorization {

  displayName: string
  url: string
  account: LoginOptions
  died: boolean

}

@Observed
export class WebDAVs extends Array<WebDAVAuthorization> {
}
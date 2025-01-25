export interface WebDAVLib {

  /**
   * @param path
   * @returns raw response
   */
  webdav_listDirectory(path: string, authorization: string): string | undefined

}
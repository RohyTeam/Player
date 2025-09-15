export interface PlaylistDao {

  id?: number
  name: string
  structure: string // only for user_created
  updatedAt: number // timestamp
  source: string // user_created, local, webdav
  boundUrl?: string
  extra?: string // for webdav

}
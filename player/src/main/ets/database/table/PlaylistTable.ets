import { Column, Table } from '@zxhhyj/storm';
import { PlaylistDao } from '../dao/PlaylistDao';

export class PlaylistTable extends Table<PlaylistDao> {
  override readonly tableName: string = "rohyplayer_playlist"
  readonly id = Column.integer("id").primaryKey(true).bindTo(this, 'id')
  readonly name = Column.text("name").bindTo(this, 'name')
  readonly structure = Column.text("structure").bindTo(this, 'structure')
  readonly updatedAt = Column.integer("updated_at").bindTo(this, 'updatedAt')
  readonly source = Column.text("playlist_source").notNull().default('user_created').bindTo(this, 'source')
  readonly boundUrl = Column.text("bound_url").default(undefined).bindTo(this, 'boundUrl')
  readonly extra = Column.text("playlist_extra").default(undefined).bindTo(this, 'extra')
}

export const Table_PlaylistDao: PlaylistTable = new PlaylistTable()
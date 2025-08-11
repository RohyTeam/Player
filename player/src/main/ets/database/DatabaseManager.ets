import { Database, DatabaseDao, RdbStoreWrapper, SQL } from '@zxhhyj/storm';
import { relationalStore } from '@kit.ArkData';
import { Table_PlaylistDao } from './table/PlaylistTable';

export class DatabaseManager extends Database {
  readonly playlistDao = DatabaseDao.form(this).select(Table_PlaylistDao)

  protected async initDb(context: Context): Promise<relationalStore.RdbStore> {
    return relationalStore.getRdbStore(
      context,
      {
        name: 'playlist.db',
        securityLevel: relationalStore.SecurityLevel.S2
      }
    )
  }

  protected onCreate(rdbStore: RdbStoreWrapper): void {
  }

  protected onDatabaseCreate(rdbStore: RdbStoreWrapper): void {
    rdbStore.executeSync(SQL.createTableAndIndex(Table_PlaylistDao))
  }
}

export let DB: DatabaseManager = new DatabaseManager(1);
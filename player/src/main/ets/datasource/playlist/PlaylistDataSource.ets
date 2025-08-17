import { PlaylistDao } from "../../database/dao/PlaylistDao";
import { DatabaseManager, DB } from "../../database/DatabaseManager";
import { Table_PlaylistDao } from "../../database/table/PlaylistTable";
import { RDataSource } from "../RDataSource";

@ObservedV2
export class PlaylistDataSource extends RDataSource<PlaylistDao> {

  constructor() {
    super(DB, Table_PlaylistDao, DB.playlistDao, (a, b) => a.name.localeCompare(b.name))
  }

}

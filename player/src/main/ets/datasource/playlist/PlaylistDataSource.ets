import { PlaylistDao } from '../../database/dao/PlaylistDao';
import { DB } from '../../database/DatabaseManager';
import { Table_PlaylistDao } from '../../database/table/PlaylistTable';
import { isPlaylistFolder, PlaylistFolder, PlaylistStructure, PlaylistVideo } from '../../playlist/PlaylistStructure';
import { RDataSource } from '../RDataSource';
import { JSON } from '@kit.ArkTS';
import { PlaylistCache } from '../../cache/PlaylistCache';

@ObservedV2
export class PlaylistDataSource extends RDataSource<PlaylistDao> {

  constructor() {
    super(DB, Table_PlaylistDao, DB.playlistDao, (a, b) => a.name.localeCompare(b.name))
  }

  public async rename(data: PlaylistDao, newName: string) {
    data.name = newName
    await super.update(data, false)
  }

  public async remove(data: PlaylistDao): Promise<void> {
    await super.remove(data)
    PlaylistCache.deleteVideos((JSON.parse(data.structure) as PlaylistStructure).items)
  }

  public async reload(): Promise<void> {
    await super.reload()
    for (let data of this.all()) {
      this.resolveItems((JSON.parse(data.structure) as PlaylistStructure).items)
    }
  }

  private resolveItems(items: (PlaylistVideo | PlaylistFolder)[]) {
    for (let item of items) {
      if (isPlaylistFolder(item)) {
        this.resolveItems((item as PlaylistFolder).items)
      } else {
        let identity = (item as PlaylistVideo).identity
        if (PlaylistCache.imported[identity]) {
          PlaylistCache.imported[identity] += 1
        } else {
          PlaylistCache.imported[identity] = 1
        }
      }
    }
  }
}

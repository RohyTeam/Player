import { Playlist } from "./Playlist";

export class PlaylistDataSource implements IDataSource {

  totalCount(): number {
    throw new Error("Method not implemented.");
  }

  getData(index: number): Playlist {
    throw new Error("Method not implemented.");
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    throw new Error("Method not implemented.");
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    throw new Error("Method not implemented.");
  }

}

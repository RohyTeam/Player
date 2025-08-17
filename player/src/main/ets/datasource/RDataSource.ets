import { Database, DatabaseDao, Table } from "@zxhhyj/storm";

export interface RData {

  id?: number

}

@ObservedV2
export abstract class RDataSource<D extends RData> implements IDataSource {

  private database: Database
  private table: Table<D>
  private dao: DatabaseDao<D>
  private sorter?: (a: D, b: D) => number

  private dataChangeListeners: DataChangeListener[] = []

  private initiallyReloading: boolean = false
  @Trace
  alreadyReloaded: boolean = false

  private loadedData: D[] = []

  constructor(database: Database, table: Table<D>, dao: DatabaseDao<D>, sorter?: (a: D, b: D) => number) {
    this.database = database
    this.table = table
    this.dao = dao
    this.sorter = sorter
  }

  public async add(data: D, alreadyInsert: boolean) {
    if (data.id != undefined && this.loadedData.findIndex((stored) => stored.id === data.id) >= 0)
      return
    if (!alreadyInsert || data.id == undefined) {
      await this.dao.insert(data)
    }
    this.loadedData.push(data)
    if (this.sorter != undefined)
      this.loadedData = this.loadedData.sort(this.sorter)

    let index = this.loadedData.findIndex((stored) => stored.id === data.id)
    this.dataChangeListeners.forEach((listener) => {
      listener.onDataAdd(index)
    })
  }

  public async update(data: D, alreadyUpdate: boolean) {
    if (data.id == undefined || this.loadedData.findIndex((stored) => stored.id === data.id) < 0)
      return
    let index = this.loadedData.findIndex((stored) => stored.id === data.id)
    if (!alreadyUpdate) {
      await this.dao.update(data)
    }
    this.dataChangeListeners.forEach((listener) => {
      listener.onDataChange(index)
    })
  }

  public async remove(data: D) {
    if (data.id == undefined || this.loadedData.findIndex((stored) => stored.id === data.id) < 0)
      return
    let index = this.loadedData.findIndex((stored) => stored.id === data.id)
    this.loadedData = this.loadedData.splice(index, 1)

    this.dataChangeListeners.forEach((listener) => {
      listener.onDataDelete(index)
    })
  }

  public async removeAt(index: number) {
    if (index < 0 || index >= this.loadedData.length)
      return
    this.loadedData = this.loadedData.splice(index, 1)

    this.dataChangeListeners.forEach((listener) => {
      listener.onDataDelete(index)
    })
  }

  public async reloadInitially() {
    if (this.alreadyReloaded || this.initiallyReloading)
      return
    this.initiallyReloading = true
    this.reload()
    this.alreadyReloaded = true
  }

  public async reload() {
    this.loadedData = await this.dao.query()
    if (this.sorter != undefined)
      this.loadedData = this.loadedData.sort(this.sorter)
    this.dataChangeListeners.forEach((listener) => {
      listener.onDataReloaded()
    })
  }

  public all(): D[] {
    let newDataArray: D[] = []
    newDataArray.push(...this.loadedData)
    return newDataArray
  }

  totalCount(): number {
    return this.loadedData.length;
  }

  getData(index: number): D {
    return this.loadedData[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.dataChangeListeners.indexOf(listener) >= 0)
      return
    this.dataChangeListeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    let index = this.dataChangeListeners.indexOf(listener)
    if (index < 0)
      return
    this.dataChangeListeners = this.dataChangeListeners.splice(index, 1)
  }

}
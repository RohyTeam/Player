export interface RohyGridItem { // implements by you own
}

@ComponentV2
export struct RohyGrid {

  @Param
  @Require
  items: RohyGridItem[]
  @Param
  @Require
  columns: number

  @BuilderParam
  itemBuilder: (item: RohyGridItem, index: number) => void

  @Local
  private thisWidth: number = 0

  build() {
    Column() {

    }
    .onAreaChange((_, newArea) => {
      let width = newArea.width
      if (typeof width == 'number') {
        this.thisWidth = width
      } else if (typeof width == 'string') {
        if (width.endsWith('px')) {
          this.thisWidth = this.getUIContext().px2vp(parseInt(width.substring(0, width.length - 2)))
        } else if (width.endsWith("vp")) {
          this.thisWidth = parseInt(width.substring(0, width.length - 2))
        } else {
          this.thisWidth = parseInt(width) ?? 0
        }
      } else {
        this.thisWidth = this.getUIContext().getHostContext()!.resourceManager.getNumber(width)
      }
    })
  }

}
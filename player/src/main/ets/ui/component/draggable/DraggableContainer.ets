export interface DraggableItem {

  index: number
  id: string
  icon: Resource
  isSymbol: boolean
  name: ResourceStr

}

@ComponentV2
export struct DraggableContainer {

  @Param
  @Require
  columns: number

  build() {
    Column() {

    }
  }

}
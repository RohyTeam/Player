import { parseLength } from "../../utils/ComponentUtils"

export enum SameWidthStrategy {

  MAX,
  MIN

}
@ComponentV2
export struct SameWidthComponent {

  @Param
  @Require
  sameId: string
  @Param
  @Require
  componentHeight: Length
  @Param
  @Require
  componentMargin: Margin

  @BuilderParam
  builder: () => void

  build() {
    Row() {
      Column() {
        this.builder()
      }
      .height(this.componentHeight)
      .attributeModifier(new SameWidthConsumerModifier(this.sameId))
      Column() {
        this.builder()
      }
      .attributeModifier(new SameWidthSupplierModifier(this.sameId, this.getUniqueId(), this.getUIContext()))
      .visibility(Visibility.None)
    }
    .alignItems(VerticalAlign.Center)
    .height(this.componentHeight)
    .margin(this.componentMargin)
  }

}

let SAME_WIDTH_CACHE: Map<string, Map<number, number>> = new Map()

class SameWidthConsumerModifier implements AttributeModifier<CommonAttribute> {

  private id: string

  constructor(id: string) {
    this.id = id
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    if (!SAME_WIDTH_CACHE.has(this.id))
      return
    let max = 0
    for (let i of SAME_WIDTH_CACHE.get(this.id)!.values()) {
      if (i > max)
        max = i
    }
    instance.width(max)
  }

}

class SameWidthSupplierModifier implements AttributeModifier<CommonAttribute> {

  private id: string
  private componentId: number
  private context: UIContext

  constructor(id: string, componentId: number, context: UIContext) {
    this.id = id
    this.componentId = componentId
    this.context = context
  }

  applyNormalAttribute(instance: CommonAttribute): void {
    instance.onAppear(() => {
      if (!SAME_WIDTH_CACHE.has(this.id))
        SAME_WIDTH_CACHE.set(this.id, new Map())
    }).onDisAppear(() => {
      if (!SAME_WIDTH_CACHE.has(this.id))
        return
      SAME_WIDTH_CACHE.get(this.id)?.delete(this.componentId)
      if (SAME_WIDTH_CACHE.get(this.id)?.size == 0)
        SAME_WIDTH_CACHE.delete(this.id)
    }).onAreaChange((_, newArea) => {
      if (!SAME_WIDTH_CACHE.has(this.id))
        SAME_WIDTH_CACHE.set(this.id, new Map())
      SAME_WIDTH_CACHE.get(this.id)?.set(this.componentId, parseLength(this.context, newArea.width))
    })
  }

}
import { WindowContext } from "../../../context/WindowContext"
import { copyArray } from "../../../utils/ArrayUtils"
import { curves } from "@kit.ArkUI"

export interface DraggableItem {

  index: number
  id: string
  icon: Resource
  isSymbol: boolean
  name: ResourceStr

}

export interface DraggableArea {

  title: ResourceStr
  max?: number
  /**
   * 允许用户自行排序
   * 关闭选项将通过 item 的 index 和 id 自动排序
   */
  ordered?: boolean
  initialItems?: DraggableItem[]
  onEvent: (event: DraggableEvent) => void

}

export interface DraggableEvent {

  items: DraggableItem[]

}

export interface DraggableRearrangeEvent extends DraggableEvent {

  items: DraggableItem[]

}

export interface DraggableAddEvent extends DraggableEvent {

  items: DraggableItem[]
  item: DraggableItem
  cancelled: boolean

}

export interface DraggableDeleteEvent extends DraggableEvent {

  items: DraggableItem[]
  item: DraggableItem

}

interface DraggingSource {

  item: DraggableItem
  delete: () => void

}

@ObservedV2
class DraggableContext {

  @Trace
  source: DraggingSource | undefined = undefined

}

const ITEM_HEIGHT: number
  = 28 + // 图标大小
    4 + // 图标上边距
    4 + // 图标下边距
    16 + // 文字高度
    4 // 文字下边距

@ComponentV2
export struct InnerDraggableContainer {

  @Provider("draggableContext")
  private draggableContext: DraggableContext = new DraggableContext()
  @Param
  @Require
  title: ResourceStr
  @Param
  subtitle: ResourceStr | undefined = undefined
  @Param
  popup: ResourceStr | undefined = undefined

  @Param
  @Require
  areas: DraggableArea[]

  @Local
  private showPopup: boolean = false

  @Builder
  popupText() {
    Column() {
      Text(this.popup)
        .fontColor($r("sys.color.font_primary"))
        .padding(16)
    }
    .constraintSize({
      maxWidth: "50%"
    })
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r("sys.color.font_primary"))
          if (this.subtitle != undefined) {
            Text(this.subtitle)
              .fontSize(14)
              .fontColor($r("sys.color.font_secondary"))
          }
        }
        .alignItems(HorizontalAlign.Start)
        .margin({
          left: 8,
          top: 8,
          bottom: 8
        })

        if (this.popup != undefined) {
          SymbolGlyph($r('sys.symbol.questionmark_circle'))
            .fontSize(20)
            .fontColor([$r('sys.color.icon_primary')])
            .onClick(() => {
              this.showPopup = true
            })
            .margin({
              left: 4
            })
            .bindPopup(
              this.showPopup,
              {
                builder: this.popupText,
                placement: Placement.Bottom,
                enableArrow: true,
                showInSubWindow: false,
                popupColor: $r("app.color.rohy_card"),
                backgroundBlurStyle: BlurStyle.NONE,
                onStateChange: (state) => {
                  if (!state.isVisible) {
                    this.showPopup = false
                  }
                }
              }
            )
        }
        Blank()
          .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .borderRadius(12)
      .width("100%")
      .backgroundColor($r("app.color.rohy_card"))
      ForEach(this.areas, (area: DraggableArea) => {
        InnerDraggableArea({
          title: area.title,
          max: area.max ?? -1,
          ordered: area.ordered ?? true,
          initialItems: area.initialItems ?? [],
          event: area.onEvent
        })
      })
    }
    .backgroundColor(Color.Transparent)
    .width("100%")
  }

}

@ObservedV2
class DraggableItems extends Array<DraggableItem> {}

@ComponentV2
export struct InnerDraggableArea {

  @Local
  private windowContext: WindowContext = WindowContext.reach(this.getUIContext())
  @Consumer("draggableContext")
  private draggableContext: DraggableContext = new DraggableContext()

  @Param
  @Require
  title: ResourceStr

  @Param
  max: number = -1
  /**
   * 允许用户自行排序
   * 关闭选项将通过 item 的 index 和 id 自动排序
   */
  @Param
  ordered: boolean = true
  @Param
  initialItems: DraggableItem[] = []

  @Local
  private items: DraggableItems = []

  @Event
  event: (event: DraggableEvent) => void

  aboutToAppear(): void {
    this.items.push(...this.initialItems)
    if (!this.ordered) {
      this.sort()
    }
  }

  private sort() {
    this.sortItems(this.items)
  }

  private sortItems(array: Array<DraggableItem>) {
    array.sort((a, b) => {
      if (a.index != b.index)
        return a.index - b.index

      return a.id.localeCompare(b.id)
    })
  }

  @Builder
  private draggableItem(item: DraggableItem) {
    Column() {
      if (item.isSymbol) {
        SymbolGlyph(item.icon)
          .fontSize(28)
          .width(28)
          .height(28)
          .margin({
            top: 4,
            left: 4,
            right: 4,
            bottom: 4
          })
          .fontColor([$r('sys.color.icon_primary')])
      } else {
        Image(item.icon)
          .width(28)
          .height(28)
          .margin({
            top: 4,
            left: 4,
            right: 4,
            bottom: 4
          })
          .fillColor($r('sys.color.icon_primary'))
      }
      Text(item.name)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.MARQUEE })
        .fontSize(14)
        .margin({
          left: 4,
          right: 4,
          bottom: 4
        })
        .fontColor($r('sys.color.font_primary'))
    }
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Text(this.title)
        .alignSelf(ItemAlign.Start)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r("sys.color.font_primary"))
        .margin({
          top: 4,
          bottom: 4
        })

      Grid(
        undefined,
        {
          regularSize: [1, 1]
        }
      ) {
        ForEach(this.items, (item: DraggableItem) => {
          GridItem() {
            this.draggableItem(item)
          }
        })
      }
      .scrollBar(BarState.Off)
      .attributeModifier(new DraggableGridLayoutModifier(this.getUIContext()))
      .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
        let item = this.items[itemIndex]
        this.draggableContext.source = {
          item: item,
          delete: () => {
            this.items.splice(itemIndex, 1)
            if (!this.ordered) {
              this.sort()
            }
            let event: DraggableDeleteEvent = {
              items: copyArray(this.items),
              item: item
            }
            this.event(event)
          }
        }
        return this.draggableItem(item)
      })
      .editMode(true)
      .onItemDrop((event: ItemDragInfo, itemIndex: number, insertIndex: number, isSuccess: boolean) => {
        if (isSuccess && this.draggableContext.source !== undefined) {
          this.drop(itemIndex, insertIndex)
        }
      })
      .columnsGap(8)
      .rowsGap(8)
      .backgroundColor($r("app.color.rohy_background"))
      .borderRadius(12)
      .width("100%")
      .animation({
        duration: 200,
        curve: curves.springMotion()
      })
      .height(this.items.length > 0 ? "auto" : 48)
    }
    .padding({
      left: 8,
      right: 8,
      bottom: 8,
    })
    .backgroundColor(Color.Transparent)
    .width("100%")
  }

  private drop(itemIndex: number, insertIndex: number) {
    if (itemIndex === -1) {
      if (insertIndex === -1) {
        // 理论上不可能存在的情况
        return
      }
      if (this.max >= 0 && this.items.length >= this.max) {
        this.draggableContext.source = undefined
        return // 对最大可选择数进行限制
      }
      let copiedArray: Array<DraggableItem>
      if (this.items.length > 0) {
        copiedArray = copyArray(this.items)
        copiedArray.splice(insertIndex, 0, this.draggableContext.source!.item)
      } else {
        copiedArray = [this.draggableContext.source!.item]
      }
      if (!this.ordered) {
        this.sortItems(copiedArray)
      }
      let event: DraggableAddEvent = {
        items: copiedArray,
        item: this.draggableContext.source!.item,
        cancelled: false
      }
      this.event(event)
      if (!event.cancelled) {
        console.error('dropping add event not cancelled')
        this.items.splice(insertIndex, 0, this.draggableContext.source!.item)
        this.draggableContext.source!.delete()
      }
      this.draggableContext.source = undefined
    } else {
      if (insertIndex === -1) {
        // 仅在投放方处理数据，拿取方不处理
        return
      }
      // 本地重排序
      if (!this.ordered) {
        // 如果不允许用户重排序，则不处理
        this.draggableContext.source = undefined
        return
      }

      let item = this.draggableContext.source!.item

      if (itemIndex == insertIndex) {
        this.draggableContext.source = undefined
        return
      }
      if (itemIndex > insertIndex) {
        this.items.splice(itemIndex, 1)
        this.items.splice(insertIndex, 0, item)
      } else {
        this.items.splice(insertIndex + 1, 0, item) // 因为删除原来的 item 后会左移一位，所以要把插入位置 + 1
        this.items.splice(itemIndex, 1)
      }
      this.draggableContext.source = undefined
      let event: DraggableRearrangeEvent = {
        items: copyArray(this.items)
      }
      this.event(event)
    }
  }

}

function rowLength(context: UIContext | Context): number {
  let windowContext = WindowContext.reach(context)
  if (windowContext.widthBreakpoint == "xs") {
    return 3
  } else if (windowContext.widthBreakpoint == "sm") {
    return 4
  } else if (windowContext.widthBreakpoint == "md") {
    return 6
  } else if (windowContext.widthBreakpoint == "lg") {
    return 7
  } else if (windowContext.widthBreakpoint == "xl") {
    return 9
  } else {
    return 10
  }
}

class DraggableGridLayoutModifier implements AttributeModifier<GridAttribute> {

  private windowContext: WindowContext

  constructor(context: UIContext) {
    this.windowContext = WindowContext.reach(context)
  }

  applyNormalAttribute(instance: GridAttribute): void {
    if (this.windowContext.widthBreakpoint == "xs") {
      instance.columnsTemplate("1fr 1fr 1fr")
    } else if (this.windowContext.widthBreakpoint == "sm") {
      instance.columnsTemplate("1fr 1fr 1fr 1fr")
    } else if (this.windowContext.widthBreakpoint == "md") {
      instance.columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr")
    } else if (this.windowContext.widthBreakpoint == "lg") {
      instance.columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr")
    } else if (this.windowContext.widthBreakpoint == "xl") {
      instance.columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr")
    } else {
      instance.columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr")
    }
  }
}
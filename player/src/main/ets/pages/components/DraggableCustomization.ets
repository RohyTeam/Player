import { BreakpointConstants } from '../../common/constants/BreakpointConstants'
import { JSON } from '@kit.ArkTS'

export interface DraggableCustomizationOption {

  symbolIcon: Resource
  name: ResourceStr

}

export interface DraggableCustomizationFunctions {

  // selected 和 unselected 都是指定顺序的
  onChange: (selected: number[], unselected: number[]) => void

}

const ITEM_HEIGHT: number = 28 + // 图标高度
  14 + // 文字高度
  16 + // 图标上边距
  4 + // 图标与文字间隔
  16 + // 文字下边距
  8; // 预留高度

@Component
export struct DraggableCustomization {
  @Prop
  @Require
  title: ResourceStr
  @Prop
  @Require
  options: DraggableCustomizationOption[] // 不可修改
  @Prop
  @Require
  functions: DraggableCustomizationFunctions
  @Prop
  max: number = -1 // 可选择的最大数量，小于 0 为不限制数量
  // 保存的是 index
  // 允许传入参数作为默认选择的，或者不传，直接全部都当作未选择
  @Prop
  @Watch("selectedWatcher")
  selected: number[] = []
  @Prop
  unselected: number[] = []
  @State
  selectedHeight: number = 48
  @State
  unselectedHeight: number = 48
  @State
  dragging: number | undefined = undefined // 如果是负数说明是从 unselect 中拖出来的
  @StorageLink('currentWidthBreakpoint')
  currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;

  selectedWatcher(changedPropertyName: string) {
    let newUnselected: number[] = []
    for (let i = 0; i < this.options.length; i++) {
      if (this.selected.indexOf(i) < 0) {
        newUnselected.push(i)
      }
    }
    animateTo({
      duration: 200,
      curve: Curve.Linear,
      playMode: PlayMode.Normal
    }, () => {
      this.unselected = newUnselected
      this.recalculateHeight()
    })
  }

  aboutToAppear(): void {
    for (let i = 0; i < this.options.length; i++) {
      if (this.selected.indexOf(i) < 0 && this.unselected.indexOf(i) < 0) {
        this.unselected.push(i) // 确保所有的数据都存在 selected 或者 unselected 中
      }
    }
    this.recalculateHeight()
  }

  @Builder
  private draggableOption(realIndex: number) {
    DraggableCustomizationItem({
      index: realIndex,
      option: this.options[realIndex]
    })
  }

  build() {
    Column() {
      Column() {
        Text(this.title)
          .alignSelf(ItemAlign.Start)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.font_primary"))
          .margin({
            top: 16,
            bottom: 4
          })
        // 已选择
        Text($r("app.string.draggable_customization_selected"))
          .alignSelf(ItemAlign.Start)
          .margin({
            top: 4,
            bottom: 16
          })
        Grid(
          undefined,
          {
            regularSize: [1, 1]
          }
        ) {
          ForEach(this.selected, (realIndex: number, index: number) => {
            GridItem() {
              this.draggableOption(realIndex)
            }
          })
        }
        .columnsTemplate(
          this.currentWidthBreakpoint == "xs" ? "1fr 1fr 1fr" : (
            this.currentWidthBreakpoint == "sm" ? "1fr 1fr 1fr 1fr" : (
              this.currentWidthBreakpoint == "md" ? "1fr 1fr 1fr 1fr 1fr" : (
                this.currentWidthBreakpoint == "lg" ? "1fr 1fr 1fr 1fr 1fr 1fr" : (
                  this.currentWidthBreakpoint == "xl" ? "1fr 1fr 1fr 1fr 1fr 1fr 1fr" :
                    "1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr"
                )
              )
            )
          )
        )
        .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
          this.dragging = itemIndex
          console.error(`select grid item drag start`)
          let optionIndex = this.selected[itemIndex]
          return this.draggableOption(optionIndex)
        })
        .editMode(true)
        .onItemDragEnter(() => {
          console.error(`select grid item drag enter`)
        })
        .onItemDragLeave(() => {
          console.error(`select grid item drag leave`)
        })
        .onItemDrop((event: ItemDragInfo, itemIndex: number, insertIndex: number, isSuccess: boolean) => {
          if (isSuccess) {
            if (this.dragging == undefined) {
              // 这意味着，用户将另一个 DraggableCustomization 的 option 拖进来了
              return
            }
            if (itemIndex == -1) {
              if (insertIndex == -1) { // 这理论上不应该出现！
                return
              }
              if (this.max >= 0 && this.selected.length >= this.max) {
                return // 对最大可选择数进行限制
              }
              let realIndex = this.unselected[-this.dragging!]
              this.selected.splice(insertIndex, 0, realIndex)
              this.unselected.splice(-this.dragging!, 1)
              // onItemDrop 会在 selected 和 unselected 中同时触发，为保证安全，只在数据处理时操作
              this.functions.onChange(this.selected, this.unselected)
            } else {
              if (insertIndex != -1) {
                let realIndex = this.selected[itemIndex]
                this.selected.splice(itemIndex, 1)
                this.selected.splice(insertIndex, 0, realIndex)
                // onItemDrop 会在 selected 和 unselected 中同时触发，为保证安全，只在数据处理时操作
                this.functions.onChange(this.selected, this.unselected)
              }
            }
            this.recalculateHeight()
          }
          console.error(`select grid item drop, event: ${JSON.stringify(event)}, itemIndex: ${itemIndex}, insertIndex: ${insertIndex}, isSuccess: ${isSuccess}`)
        })
        .columnsGap(8)
        .rowsGap(8)
        .backgroundColor($r("app.color.rohy_settings_background"))
        .borderRadius(24)
        .width("100%")
        .height(this.selectedHeight)

        Text($r("app.string.draggable_customization_unselected"))
          .alignSelf(ItemAlign.Start)
          .margin({
            top: 16,
            bottom: 16
          })
        Grid(
          undefined,
          {
            regularSize: [1, 1]
          }
        ) {
          ForEach(this.unselected, (realIndex: number, index: number) => {
            GridItem() {
              this.draggableOption(realIndex)
            }
          })
        }
        .editMode(true)
        .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
          this.dragging = -itemIndex
          console.error(`unselect grid item drag start`)
          let optionIndex = this.unselected[itemIndex]
          return this.draggableOption(optionIndex)
        })
        .onItemDragEnter(() => {
          console.error(`unselect grid item drag enter`)
        })
        .onItemDragLeave(() => {
          console.error(`unselect grid item drag leave`)
        })
        .onItemDrop((event: ItemDragInfo, itemIndex: number, insertIndex: number, isSuccess: boolean) => {
          if (isSuccess) {
            if (this.dragging == undefined) {
              // 这意味着，用户将另一个 DraggableCustomization 的 option 拖进来了
              return
            }
            if (itemIndex == -1) {
              if (insertIndex == -1) { // 这理论上不应该出现！
                return
              }
              let realIndex = this.selected[this.dragging!]
              this.unselected.splice(insertIndex, 0, realIndex)
              this.selected.splice(this.dragging!, 1)
              // onItemDrop 会在 selected 和 unselected 中同时触发，为保证安全，只在数据处理时操作
              this.functions.onChange(this.selected, this.unselected)
            } else {
              if (insertIndex != -1) {
                let realIndex = this.unselected[itemIndex]
                this.unselected.splice(itemIndex, 1)
                this.unselected.splice(insertIndex, 0, realIndex)
                // onItemDrop 会在 selected 和 unselected 中同时触发，为保证安全，只在数据处理时操作
                this.functions.onChange(this.selected, this.unselected)
              }
            }
            this.recalculateHeight()
          }
          console.error(`unselect grid item drop, event: ${JSON.stringify(event)}, itemIndex: ${itemIndex}, insertIndex: ${insertIndex}, isSuccess: ${isSuccess}`)
        })
        .columnsTemplate(
          this.currentWidthBreakpoint == "xs" ? "1fr 1fr 1fr" : (
            this.currentWidthBreakpoint == "sm" ? "1fr 1fr 1fr 1fr" : (
              this.currentWidthBreakpoint == "md" ? "1fr 1fr 1fr 1fr 1fr" : (
                this.currentWidthBreakpoint == "lg" ? "1fr 1fr 1fr 1fr 1fr 1fr" : (
                  this.currentWidthBreakpoint == "xl" ? "1fr 1fr 1fr 1fr 1fr 1fr 1fr" :
                    "1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr"
                )
              )
            )
          )
        )
        .backgroundColor($r("app.color.rohy_settings_background"))
        .borderRadius(24)
        .width("100%")
        .margin({
          bottom: 16
        })
        .height(this.unselectedHeight)
      }
      .padding({
        left: 16,
        right: 16
      })
      .backgroundColor($r("app.color.rohy_settings_card"))
      .borderRadius(24)
      .width("90%")
    }
    .backgroundColor(Color.Transparent)
    .width("100%")
  }

  private recalculateHeight() {
    let widgetWidth = this.currentWidthBreakpoint == "xs" ? 3 : (
      this.currentWidthBreakpoint == "sm" ? 4 : (
        this.currentWidthBreakpoint == "md" ? 5 : (
          this.currentWidthBreakpoint == "lg" ? 6 : (
            this.currentWidthBreakpoint == "xl" ? 7 : 8
          )
        )
      )
    )
    let selectedAmount = this.selected.length
    let unselectedAmount = this.unselected.length
    let selectedLines = Math.ceil(selectedAmount / widgetWidth)
    let unselectedLines = Math.ceil(unselectedAmount / widgetWidth)
    // 如果没有控件就留 48 高的空
    this.selectedHeight =
      selectedLines == 0 ? 48 : selectedLines * ITEM_HEIGHT + ((selectedLines - 1) * 8) // 尾部是为间隔预留的空间
    this.unselectedHeight =
      unselectedLines == 0 ? 48 : unselectedLines * ITEM_HEIGHT + ((unselectedLines - 1) * 8) // 尾部是为间隔预留的空间
  }
}

@Component
struct DraggableCustomizationItem {
  @Prop
  @Require
  index: number
  @Prop
  @Require
  option: DraggableCustomizationOption

  build() {
    Column() {
      Column() {
        SymbolGlyph(this.option.symbolIcon)
          .fontSize(28)
          .width(28)
          .height(28)
          .margin({
            top: 16,
            left: 16,
            right: 16,
            bottom: 4
          })
          .fontColor([$r('app.color.icon_primary')])
        Text(this.option.name)
          .fontSize(14)
          .margin({
            left: 16,
            right: 16,
            bottom: 16
          })
          .fontColor($r('app.color.font_primary'))
      }
    }
  }
}
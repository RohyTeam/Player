import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI'
import { DialogHelper } from '@pura/harmony-dialog'

export interface RohyMenuItem {

  options: MenuItemOptions
  action: (event: ClickEvent) => void

}

@ObservedV2
export class RohyMenuGroup {
  @Trace
  items: RohyMenuItem[] = []
}

export function buildMenuGroup(builder: () => RohyMenuItem[] | undefined): RohyMenuGroup | undefined {
  let items = builder()
  if (items == undefined || items.length == 0) {
    return undefined
  }
  let menuGroup = new RohyMenuGroup()
  menuGroup.items = items
  return menuGroup
}

export function menuGroups(builder: () => (RohyMenuGroup | undefined)[]): RohyMenuGroup[] {
  let groups: RohyMenuGroups = []
  for (let group of builder()) {
    if (!group) {
      continue
    }
    groups.push(group)
  }
  return groups
}

export class RohyMenuGroups extends Array<RohyMenuGroup> {
}

@ComponentV2
export struct RohyMenu {
  @Param
  @Require
  groups: RohyMenuGroups

  build() {
    Menu() {
      ForEach(this.groups, (group: RohyMenuGroup, groupIndex) => {
        MenuItemGroup() {
          ForEach(group.items, (item: RohyMenuItem, itemIndex) => {
            InternalRohyMenuItem({
              menuItem: item,
              itemIndex: itemIndex,
              groupIndex: groupIndex,
              totalGroups: this.groups.length,
              totalItems: group.items.length
            })
          })
          if (groupIndex != this.groups.length - 1) {
            // 解决 MenuGroup 的 Divider 回和前一个 MenuGroup 的重叠的问题
            MenuItem()
              .margin({
                bottom: 8
              })
          }
        }
      })
    }
    .menuItemDivider({
      color: $r("sys.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(1),
      startMargin: LengthMetrics.vp(4),
      endMargin: LengthMetrics.vp(4)
    })
    .menuItemGroupDivider({
      color: $r("sys.color.comp_background_tertiary"),
      strokeWidth: LengthMetrics.vp(8),
      startMargin: LengthMetrics.vp(0),
      endMargin: LengthMetrics.vp(0)
    })
    .padding(0)
    .subMenuExpandingMode(SubMenuExpandingMode.EMBEDDED_EXPAND)
  }
}

@ComponentV2
struct InternalRohyMenuItem {

  @Param
  @Require
  menuItem: RohyMenuItem
  @Param
  @Require
  groupIndex: number
  @Param
  @Require
  itemIndex: number
  @Param
  @Require
  totalGroups: number
  @Param
  @Require
  totalItems: number

  build() {
    MenuItem(this.menuItem.options)
      .margin({
        left: 4,
        right: 4,
        top: this.groupIndex == 0 && this.itemIndex == 0 ? 4 : 0,
        bottom: this.groupIndex == this.totalGroups - 1 && this.itemIndex == this.totalItems - 1 ? 4 : 0
      })
      .onClick(this.menuItem.action)
  }

}
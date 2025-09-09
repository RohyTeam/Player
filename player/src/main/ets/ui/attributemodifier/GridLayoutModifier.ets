import { WindowContext } from '../../context/WindowContext'

export class GridLayoutModifier implements AttributeModifier<GridAttribute> {
  private windowContext: WindowContext

  constructor(context: UIContext) {
    this.windowContext = WindowContext.reach(context)
  }

  applyNormalAttribute(instance: GridAttribute): void {
    if (this.windowContext.widthBreakpoint == "xs") {
      instance.columnsTemplate("1fr 1fr")
    } else if (this.windowContext.widthBreakpoint == "sm") {
      instance.columnsTemplate("1fr 1fr 1fr")
    } else if (this.windowContext.widthBreakpoint == "md") {
      instance.columnsTemplate("1fr 1fr 1fr 1fr 1fr")
    } else if (this.windowContext.widthBreakpoint == "lg") {
      instance.columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr")
    } else if (this.windowContext.widthBreakpoint == "xl") {
      instance.columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr")
    } else {
      instance.columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr")
    }
  }
}
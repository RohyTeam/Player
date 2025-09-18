import { ensureContext } from "./AbilityUtils"

export function parseLength(context: UIContext, length: Length): number {
  if (typeof length == 'number') {
    return length
  } else if (typeof length == 'string') {
    if (length.endsWith('px')) {
      return context.px2vp(parseInt(length.substring(0, length.length - 2)))
    } else if (length.endsWith("vp")) {
      return parseInt(length.substring(0, length.length - 2))
    } else {
      return parseInt(length) ?? 0
    }
  } else {
    return ensureContext(context).resourceManager.getNumber(length)
  }
}

export function getWidthBreakpointSize(breakpoint: string): number {
  switch (breakpoint) {
    case "xs":
      return 0
    case 'sm':
      return 1
    case 'md':
      return 2
    case 'lg':
      return 3
    case 'xl':
      return 4
    default:
      return 5
  }
}
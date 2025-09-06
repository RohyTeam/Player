export function divideAndFloor(dividend: number, divisor: number) {
  return Math.floor(dividend / divisor);
}

export function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(value, max))
}

export function keepNumber(value: number, length: number): string {
  if (length <= 0) {
    return `${Math.round(value)}`
  }
  let numberString = `${value}`
  if (numberString.indexOf('.') < 0) {
    numberString += '.'
    for (let i = 0; i < length; i++) {
      numberString += '0'
    }
    return numberString
  } else {
    let rightPart = numberString.split(".")[1]
    if (rightPart.length == length) {
      return numberString
    }
    let leftPart = numberString.split(".")[0]
    leftPart += "."
    let rightLength = 0
    for (let i = 0; i < Math.min(rightPart.length, length); i++) {
      leftPart += rightPart[i]
      rightLength += 1
    }
    while (rightLength < length) {
      leftPart += "0"
      rightLength += 1
    }
    return leftPart
  }
}
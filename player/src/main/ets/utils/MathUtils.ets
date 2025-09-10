import { Decimal } from "@kit.ArkTS";

export function divideAndFloor(dividend: number, divisor: number) {
  return Math.floor(dividend / divisor);
}

export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(value, max))
}

export function decimalClamp(value: Decimal, min: Decimal, max: Decimal): Decimal {
  return Decimal.max(min, Decimal.min(value, max))
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

export function formatDecimal(value: number | string, step: number | string): number {
  const valueStr = typeof value === 'number' ? value.toString() : value;
  const stepStr = typeof step === 'number' ? step.toString() : step;

  const stepDecimalPlaces = stepStr.includes('.') ? stepStr.split('.')[1].length : 0;

  if (valueStr.includes('e')) {
    throw new Error('Scientific notation not supported in this implementation');
  }

  const isNegative = valueStr.startsWith('-');
  const numStr = isNegative ? valueStr.slice(1) : valueStr;

  let integerPart: string
  let decimalPart: string
  if (numStr.includes('.')) {
    let split = numStr.split('.')
    integerPart = split[0]
    decimalPart = split[1]
  } else {
    integerPart = numStr
    decimalPart = ''
  }

  if (stepDecimalPlaces <= 0) {
    if (isNegative) {
      return parseInt(`-${integerPart}`)
    } else {
      return parseInt(integerPart)
    }
  }

  const truncatedDecimal = decimalPart.substring(0, stepDecimalPlaces);

  if (truncatedDecimal.length <= 0) {
    if (isNegative) {
      return parseInt(`-${integerPart}`)
    } else {
      return parseInt(integerPart)
    }
  } else {
    const result = `${integerPart}.${truncatedDecimal}`
    if (isNegative) {
      return parseInt(`-${result}`)
    } else {
      return parseInt(result)
    }
  }
}

export function formatDecimalNumber(value: number, step: number): number {
  const stepDecimals = countDecimals(step);

  if (stepDecimals <= 0) {
    return Math.trunc(value);
  }

  const factor = Math.pow(10, stepDecimals);
  return Math.round(Math.trunc(value * factor * 10) / 10) / factor;
}

function countDecimals(num: number): number {
  if (Math.floor(num) === num) return 0;

  const str = num.toString();
  if (str.includes('e')) {
    const match = str.match(/(?:\.(\d+))?(?:e([+-]?\d+))?$/i);
    if (!match) return 0;

    const decimals = match[1] ? match[1].length : 0;
    const exponent = parseInt(match[2] || '0');
    return Math.max(0, decimals - exponent);
  }

  return str.includes('.') ? str.split('.')[1].length : 0;
}
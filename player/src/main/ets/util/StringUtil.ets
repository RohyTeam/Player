export function abgrColorStr2argbColor(colorStr: string): string {
  return `#${reverseHexColor(colorStr.substring(0, 2))}${colorStr.substring(6, 8)}${colorStr.substring(4,
    6)}${colorStr.substring(2, 4)}`.toLowerCase()
}

export function abgrColorStr2rgbColor(colorStr: string): string {
  return `#${colorStr.substring(6, 8)}${colorStr.substring(4, 6)}${colorStr.substring(2, 4)}`.toLowerCase()
}

export function bgrColorStr2rgbColor(colorStr: string): string {
  return `#${colorStr.substring(4, 6)}${colorStr.substring(2, 4)}${colorStr.substring(0, 2)}`.toLowerCase()
}

export function reverseHexColor(content: string): string {
  let result = ""
  for (let char of content) {
    if (char == "0") {
      result += "F"
    } else if (char == "1") {
      result += "E"
    } else if (char == "2") {
      result += "D"
    } else if (char == "3") {
      result += "C"
    } else if (char == "4") {
      result += "B"
    } else if (char == "5") {
      result += "A"
    } else if (char == "6") {
      result += "9"
    } else if (char == "7") {
      result += "8"
    } else if (char == "8") {
      result += "7"
    } else if (char == "9") {
      result += "6"
    } else if (char == "A") {
      result += "5"
    } else if (char == "B") {
      result += "4"
    } else if (char == "C") {
      result += "3"
    } else if (char == "D") {
      result += "2"
    } else if (char == "E") {
      result += "1"
    } else if (char == "F") {
      result += "0"
    }
  }
  return result
}

export function randomString(length: number,
  chars: string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"): string {
  let result = ""
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

export function limitStringLength(value: string, maxLength: number): string {
  if (value.length > maxLength) {
    return value.substring(0, maxLength)
  }
  return value
}

export function reverseString(value: string): string {
  let result = ""
  for (let i = value.length - 1; i >= 0; i--) {
    result += value.charAt(i)
  }
  return result
}
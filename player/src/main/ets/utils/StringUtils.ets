import { util } from '@kit.ArkTS'

export function randomString(
  length: number,
  chars: string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
): string {
  let result = ""
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return result
}

function isBlankChar(char: string): boolean {
  if (char.length <= 0)
    return true
  return char == '\u0020' ||
    char == '\u00A0' ||
    char == '\u2000' ||
    char == '\u2001' ||
    char == '\u2002' ||
    char == '\u2003' ||
    char == '\u2004' ||
    char == '\u2005' ||
    char == '\u2006' ||
    char == '\u2007' ||
    char == '\u2008' ||
    char == '\u2009' ||
    char == '\u200A' ||
    char == '\u2028' ||
    char == '\u205F' ||
    char == '\u3000' ||
    char == '\n' ||
    char == '\t'
}

export function isBlank(value: string): boolean {
  for (let char of value) {
    if (!isBlankChar(char))
      return false
  }
  return true
}

export function isEmptyOrBlank(value: string): boolean {
  if (value.length <= 0)
    return true
  return isBlank(value)
}

export function stringToBytes(value: string): Uint8Array {
  let encoder = util.TextEncoder.create('utf-8')
  return encoder.encodeInto(value)
}

export function stringToBase64(value: string): string {
  let base64helper = new util.Base64Helper()
  return base64helper.encodeToStringSync(stringToBytes(value))
}

export function bytesToString(src: Uint8Array): string {
  const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true })
  return textDecoder.decodeToString(src, { stream: true });
}

export function bufferToString(src: ArrayBuffer): string {
  const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true })
  return textDecoder.decodeToString(new Uint8Array(src), { stream: true });
}
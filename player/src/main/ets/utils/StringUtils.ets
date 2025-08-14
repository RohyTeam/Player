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
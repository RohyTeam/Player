import { hash } from "@kit.CoreFileKit"
import { stringToBytes } from "./StringUtils"

export function sha256(value: string): string {
  let hasher = hash.createHash("sha256")
  hasher.update(stringToBytes(value).buffer)
  return hasher.digest()
}
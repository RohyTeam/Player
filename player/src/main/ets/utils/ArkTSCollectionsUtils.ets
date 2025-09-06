import { collections } from '@kit.ArkTS';

export function arrayBufferCollectionsToES5(array: collections.ArrayBuffer): ArrayBuffer {
  return Uint8Array.from(new collections.Uint8Array(array)).buffer as ArrayBuffer
  /*
  let container = new Uint8Array(new ArrayBuffer(array.byteLength))
  let supplier = new collections.Uint8Array(array)
  for (let i = 0; i < supplier.byteLength; i++) {
    container[i] = supplier[i]
  }
  return container.buffer as ArrayBuffer*/
}
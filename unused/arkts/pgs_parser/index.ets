import { DisplaySet, parseDisplaySetsFromBuffer } from "./parser";

export namespace Pgs {

  export function parse(buffer: ArrayBuffer): DisplaySet[] {
    return parseDisplaySetsFromBuffer(buffer)
  }

}
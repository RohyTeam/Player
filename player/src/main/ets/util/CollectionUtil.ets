export function iterableToArray<T>(iterable: IterableIterator<T>): T[] {
  let array: T[] = []
  for (let t of iterable) {
    array.push(t)
  }
  return array
}
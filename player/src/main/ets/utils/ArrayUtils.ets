export function copyArray<T>(array: Array<T>): Array<T> {
  let newArray: Array<T> = []
  newArray.push(...array)
  return newArray
}
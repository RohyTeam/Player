import { divideAndFloor } from "./MathUtil"

export function convertNumberToDurationString(num: number): string {
  let left = num
  let hours = divideAndFloor(left, 60 * 60 * 1000)
  left = left - hours * (60 * 60 * 1000)
  let minutes = divideAndFloor(left, 60 * 1000)
  left = left - minutes * (60 * 1000)
  let seconds = divideAndFloor(left, 1000)
  if (hours == 0) {
    return `${minutes.toFixed(0).padStart(2, '0')}:${seconds.toFixed(0).padStart(2, '0')}`
  } else {
    return `${hours.toFixed(0).padStart(2, '0')}:${minutes.toFixed(0).padStart(2, '0')}:${seconds.toFixed(0).padStart(2, '0')}`
  }
}
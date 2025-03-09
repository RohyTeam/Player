import { DateUtil } from '@pura/harmony-utils'
import { divideAndFloor } from './MathUtil'

export function convertNumberToDurationString(num: number): string {
  if (num == -1) {
    return "未知"
  }
  let left = num
  let hours = divideAndFloor(left, 60 * 60 * 1000)
  left = left - hours * (60 * 60 * 1000)
  let minutes = divideAndFloor(left, 60 * 1000)
  left = left - minutes * (60 * 1000)
  let seconds = divideAndFloor(left, 1000)
  if (hours == 0) {
    return `${minutes.toFixed(0).padStart(2, '0')}:${seconds.toFixed(0).padStart(2, '0')}`
  } else {
    return `${hours.toFixed(0).padStart(2, '0')}:${minutes.toFixed(0).padStart(2, '0')}:${seconds.toFixed(0)
      .padStart(2, '0')}`
  }
}

export function currentFormattedTime(): string {
  return DateUtil.getFormatDateStr(Date.now(), 'yyyy-MM-dd HH:mm:ss')
}

export function formattedStringToDate(formattedString: string, format: string): Date {
  let yearIndex = format.indexOf('yyyy')
  let monthIndex = format.indexOf('MM')
  let dayIndex = format.indexOf('dd')
  let hourIndex = format.indexOf('HH')
  let minuteIndex = format.indexOf('mm')
  let secondIndex = format.indexOf('ss')
  let millSecondIndex = formattedString.indexOf('fff')

  let year = 0
  let month = 0
  let day = 0
  let hour = 0
  let minute = 0
  let second = 0
  let millSecond = 0

  if (yearIndex >= 0) {
    year = parseInt(formattedString.substring(yearIndex, yearIndex + 4)) || 0
  }
  if (monthIndex >= 0) {
    month = parseInt(formattedString.substring(monthIndex, monthIndex + 2)) || 0
  }
  if (dayIndex >= 0) {
    day = parseInt(formattedString.substring(dayIndex, dayIndex + 2)) || 0
  }
  if (hourIndex >= 0) {
    hour = parseInt(formattedString.substring(hourIndex, hourIndex + 2)) || 0
  }
  if (minuteIndex >= 0) {
    minute = parseInt(formattedString.substring(minuteIndex, minuteIndex + 2)) || 0
  }
  if (secondIndex >= 0) {
    second = parseInt(formattedString.substring(secondIndex, secondIndex + 2)) || 0
  }
  if (millSecondIndex >= 0) {
    millSecond = parseInt(formattedString.substring(millSecondIndex, millSecondIndex + 3)) || 0
  }

  return new Date(year, month - 1, day, hour, minute, second, millSecond)
}
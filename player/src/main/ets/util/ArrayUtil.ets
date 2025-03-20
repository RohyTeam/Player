export function exclude(original: Array<number>, excluded: Array<number>): Array<number> {
  return original.filter((item) => !excluded.includes(item));
}
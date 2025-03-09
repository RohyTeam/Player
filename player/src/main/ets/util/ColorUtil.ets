export function rgbToHex(rgb: number): string {
  return `#${rgb.toString(16).padStart(6, '0')}`;
}
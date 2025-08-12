import { settings } from '@kit.BasicServicesKit'
import { superContext } from './AbilityUtils'

export function getScreenBrightness(): number {
  return parseInt(settings.getValueSync(superContext(), settings.display.SCREEN_BRIGHTNESS_STATUS,
    settings.domainName.DEVICE_SHARED))
}
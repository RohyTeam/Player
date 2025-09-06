import { settings } from '@kit.BasicServicesKit'
import { ensureContext } from './AbilityUtils'

export function getScreenBrightness(context: Context | UIContext): number {
  return parseInt(settings.getValueSync(ensureContext(context), settings.display.SCREEN_BRIGHTNESS_STATUS,
    settings.domainName.DEVICE_SHARED))
}
import { PCIndex } from './2in1/PCIndex';
import { GeneralDeviceIndex } from './generaldevice/GeneralDeviceIndex';
import { Sys } from '../../context/SystemContext';
import { PreferenceContext } from '../../context/PreferenceContext';
import { AppStorageV2 } from '@kit.ArkUI';

interface CJLib {
  testCJ(src: string): string
}

@Entry
@ComponentV2
struct Index {
  @Local
  preferenceContext: PreferenceContext =
    AppStorageV2.connect(PreferenceContext, "preferences", () => new PreferenceContext())!

  build() {
    RelativeContainer() {
      if (Sys.isPC()) {
        PCIndex()
      } else {
        GeneralDeviceIndex()
      }
    }
    .backgroundColor($r("app.color.rohy_background"))
  }
}
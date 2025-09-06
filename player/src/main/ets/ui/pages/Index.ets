import { PCIndex } from './2in1/PCIndex';
import { GeneralDeviceIndex } from './generaldevice/GeneralDeviceIndex';
import { Sys } from '../../context/SystemContext';

@Entry
@ComponentV2
struct Index {
  /**
   * ComponentV2 目前不支持 WithTheme
   */
  build() {
    RelativeContainer() {
      if (Sys.isPC()) {
        PCIndex()
      } else {
        GeneralDeviceIndex()
      }
    }
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.rohy_background"))
  }
}
import { PCIndex } from "./2in1/PCIndex";
import { GeneralDeviceIndex } from './generaldevice/GeneralDeviceIndex';
import { Sys } from '../../context/SystemContext';

interface CJLib {
  testCJ(src: string): string
}

@Entry
@ComponentV2
struct Index {

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
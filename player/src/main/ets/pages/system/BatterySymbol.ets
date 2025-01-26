import { batteryInfo } from "@kit.BasicServicesKit";
import VideoAbility from "../../ability/VideoAbility";

@Component
export struct BatterySymbol {

  aboutToAppear(): void {

  }

  build() {
    if (batteryInfo.nowCurrent == 0) {
      SymbolGlyph($r("sys.symbol.battery"))
    } else if (batteryInfo.nowCurrent <= 5) {
      SymbolGlyph($r("sys.symbol.battery_5percent"))
    } else if (batteryInfo.nowCurrent <= 10) {
      SymbolGlyph($r("sys.symbol.battery_10percent"))
    } else if (batteryInfo.nowCurrent <= 15) {
      SymbolGlyph($r("sys.symbol.battery_15percent"))
    } else if (batteryInfo.nowCurrent <= 20) {
      SymbolGlyph($r("sys.symbol.battery_20percent"))
    } else if (batteryInfo.nowCurrent <= 30) {
      SymbolGlyph($r("sys.symbol.battery_30percent"))
    } else if (batteryInfo.nowCurrent <= 40) {
      SymbolGlyph($r("sys.symbol.battery_40percent"))
    } else if (batteryInfo.nowCurrent <= 50) {
      SymbolGlyph($r("sys.symbol.battery_50percent"))
    } else if (batteryInfo.nowCurrent <= 60) {
      SymbolGlyph($r("sys.symbol.battery_60percent"))
    } else if (batteryInfo.nowCurrent <= 70) {
      SymbolGlyph($r("sys.symbol.battery_70percent"))
    } else if (batteryInfo.nowCurrent <= 75) {
      SymbolGlyph($r("sys.symbol.battery_75percent"))
    } else if (batteryInfo.nowCurrent <= 80) {
      SymbolGlyph($r("sys.symbol.battery_80percent"))
    } else if (batteryInfo.nowCurrent <= 90) {
      SymbolGlyph($r("sys.symbol.battery_90percent"))
    } else if (batteryInfo.nowCurrent <= 100) {
      SymbolGlyph($r("sys.symbol.battery_100percent"))
    } else {
      SymbolGlyph($r("sys.symbol.battery"))
    }
  }

}
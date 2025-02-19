import { SystemBasicInfo } from '../../../sendable/SystemBasicInfo';

@ComponentV2
export struct BlueToothBatteryInfo {
  @Param
  @Require
  systemBasicInfo: SystemBasicInfo

  build() {
    Stack() {
      if (this.systemBasicInfo.isCharging) {
        SymbolGlyph($r("sys.symbol.battery"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery == 0) {
        SymbolGlyph($r("sys.symbol.battery"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 7) {
        SymbolGlyph($r("sys.symbol.battery_5percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 12) {
        SymbolGlyph($r("sys.symbol.battery_10percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 17) {
        SymbolGlyph($r("sys.symbol.battery_15percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 23) {
        SymbolGlyph($r("sys.symbol.battery_20percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 33) {
        SymbolGlyph($r("sys.symbol.battery_30percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 43) {
        SymbolGlyph($r("sys.symbol.battery_40percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 53) {
        SymbolGlyph($r("sys.symbol.battery_50percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 63) {
        SymbolGlyph($r("sys.symbol.battery_60percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 73) {
        SymbolGlyph($r("sys.symbol.battery_70percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 78) {
        SymbolGlyph($r("sys.symbol.battery_75percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 83) {
        SymbolGlyph($r("sys.symbol.battery_80percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 95) {
        SymbolGlyph($r("sys.symbol.battery_90percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else if (this.systemBasicInfo.battery <= 100) {
        SymbolGlyph($r("sys.symbol.battery_100percent"))
          .fontSize(20)
          .fontColor([$r("app.color.icon_primary")])
      } else {
        SymbolGlyph($r("sys.symbol.battery"))
          .fontSize(20)
          .rotate({
            x: 0,
            y: 0,
            z: 1,
            angle: 90,
            centerX: "50%",
            centerY: "50%"
          })
          .fontColor([$r("app.color.icon_primary")])
      }
      SymbolGlyph($r("sys.symbol.bluetooth_earphone"))
        .fontSize(16)
        .fontColor([$r("app.color.icon_primary")])
    }
  }
}
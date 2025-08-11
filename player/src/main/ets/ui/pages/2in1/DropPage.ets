@ComponentV2
export struct DropPage {
  build() {
    Stack() {
      Column() {
        Blank()
          .layoutWeight(1)
        SymbolGlyph($r("sys.symbol.arrowshape_down_to_line_fill"))
          .fontColor([$r("sys.color.font_fourth")])
          .fontSize(36)
        Text($r("app.string.drop_tips"))
          .fontColor($r("sys.color.font_fourth"))
          .fontSize(24)
        Blank()
          .layoutWeight(1)
      }
      .width("100%")
      .height("100%")
      .backgroundColor(Color.Transparent)
    }
    .width("100%")
    .height("100%")
    .backgroundColor(Color.Transparent)
  }
}
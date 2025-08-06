import { uniformDataStruct, uniformTypeDescriptor } from "@kit.ArkData"
import { Dialoger } from "../../dialog/Dialoger"

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
    .allowDrop([uniformTypeDescriptor.UniformDataType.VIDEO])
    .onDrop((event, params) => {
      Dialoger.alert(this.getUIContext(), undefined, "当前还未支持拖拽播放")
      /*
      if (event.getData().getRecords().length != 1) {
        Dialoger.alert(this.getUIContext(), undefined, "一次只能播放一个文件")
        return
      }
      let record = event.getData().getRecords()[0]
      let fileInfo = record.getEntry(uniformTypeDescriptor.UniformDataType.FILE_URI) as uniformDataStruct.FileUri
      let path = fileUri.getUriFromPath(fileInfo.oriUri)
      */
    })
    .width("100%")
    .height("100%")
    .backgroundColor(Color.Transparent)
  }

}

interface FileInfo {

  oriUri: string
  remoteUri: string

}
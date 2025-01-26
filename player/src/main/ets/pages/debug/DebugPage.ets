import { drawing } from "@kit.ArkGraphics2D"

@Component
export struct DebugPage {

  aboutToAppear(): void {
  }

  build() {
    NavDestination() {
      Row() {
        Stack() {
          Text("测")
            .fontWeight(FontWeight.Bold)
            .fontSize(18)
          Text("测")
            .fontColor(Color.White)
            .fontWeight(FontWeight.Regular)
            .fontSize(16)
        }
        Stack() {
          Text("试")
            .fontWeight(FontWeight.Bold)
            .fontSize(18)
          Text("试")
            .fontColor(Color.White)
            .fontWeight(FontWeight.Regular)
            .fontSize(16)
        }
        Stack() {
          Text("文")
            .fontWeight(FontWeight.Bold)
            .fontSize(18)
          Text("文")
            .fontColor(Color.White)
            .fontWeight(FontWeight.Regular)
            .fontSize(16)
        }
        Stack() {
          Text("本")
            .fontWeight(FontWeight.Bold)
            .fontSize(18)
          Text("本")
            .fontColor(Color.White)
            .fontWeight(FontWeight.Regular)
            .fontSize(16)
        }
      }
    }
    .width("100%")
    .height("100%")
  }

}
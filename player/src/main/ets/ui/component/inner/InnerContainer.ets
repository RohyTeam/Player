import { BottomAvoidArea } from '../../avoidarea/BottomAvoidArea'

@ComponentV2
export struct InnerContainer {
  @Param
  bgColor: ResourceColor = $r("app.color.rohy_background")
  @BuilderParam
  content: () => void

  build() {
    Column() {
      this.content()
      BottomAvoidArea()
    }
    .width("100%")
    .backgroundColor(this.bgColor)
  }
}
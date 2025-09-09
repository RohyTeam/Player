import { BottomAvoidArea } from '../../avoidarea/BottomAvoidArea'

@ComponentV2
export struct InnerContainer {
  @Param
  bgColor: ResourceColor = $r("app.color.rohy_background")
  @Param
  edgeEffect: boolean = true
  @Param
  staticBottomAvoid: boolean = true
  @BuilderParam
  content: () => void

  build() {
    Scroll() {
      Column() {
        this.content()
        BottomAvoidArea({
          static: this.staticBottomAvoid
        })
      }
      .width("100%")
      .backgroundColor(this.bgColor)
    }
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: this.edgeEffect })
    .width("100%")
    .backgroundColor(this.bgColor)
  }
}
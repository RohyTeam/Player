import { Sys } from '../../../context/SystemContext'
import { BottomAvoidArea } from '../../avoidarea/BottomAvoidArea'

@ComponentV2
export struct InnerContainer {
  @Param
  bgColor: ResourceColor = $r("app.color.rohy_background")
  @Param
  fillHeight: boolean = false
  @Param
  edgeEffect: boolean = true
  @Param
  scrollBar: boolean = true
  @Param
  staticBottomAvoid: boolean = true
  @BuilderParam
  content: () => void

  build() {
    Scroll() {
      Column() {
        this.content()
        if (!Sys.isTablet()) {
          BottomAvoidArea({
            static: this.staticBottomAvoid
          })
        }
      }
      .height(this.fillHeight ? "100%" : undefined)
      .width("100%")
      .backgroundColor(this.bgColor)
    }
    .scrollBar(this.scrollBar ? BarState.On : BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: this.edgeEffect })
    .width("100%")
    .backgroundColor(this.bgColor)
    .height(this.fillHeight ? "100%" : undefined)
  }
}
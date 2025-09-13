import { WrappedTextModifier } from "../../attributemodifier/wrapper/WrappedTextModifier"
import { CircleIconButton } from "../../button/CircleIconButton"
import { WrappedText } from "../wrapper/WrappedText"

export interface SheetContainerRoute {

  title: ResourceStr
  builder: WrappedBuilder<[]>

}

@ComponentV2
export struct SheetContainer {

  @Provider("sheetNavigator")
  private sheetNavigator: NavPathStack = new NavPathStack()

  @Param
  @Require
  title: WrappedText

  @Param
  routes: Record<string, SheetContainerRoute> = {}

  @Event
  onClose: () => void

  @BuilderParam
  content: () => void

  build() {
    RelativeContainer() {
      Navigation(this.sheetNavigator) {
        Column() {
          Row() {
            Text(this.title.text)
              .fontWeight(FontWeight.Bold)
              .fontSize(20)
              .fontColor($r('sys.color.font_primary'))
              .margin({
                left: 16,
                top: 24
              })
              .attributeModifier(new WrappedTextModifier(this.title))
          }
          .alignItems(VerticalAlign.Top)
          .height(64)
          .width("100%")
          Column() {
            this.content()
          }
          .layoutWeight(1)
          .width("100%")
        }
        .width("100%")
        .height("100%")
      }
      .backgroundColor(Color.Transparent)
      .navDestination(this.route)
      .hideTitleBar(true)
      .hideBackButton(true)
      .hideToolBar(true)
      .mode(NavigationMode.Stack)
      .width("100%")
      .height("100%")

      CircleIconButton({
        icon: $r('sys.symbol.xmark'),
        clickCallback: () => {
          this.onClose()
        },
        buttonMargin: {
          top: 16,
          right: 16
        }
      })
        .alignRules({
          right: {
            anchor: '__container__',
            align: HorizontalAlign.End
          },
          top: {
            anchor: '__container__',
            align: VerticalAlign.Top
          }
        })
    }
    .backgroundColor(Color.Transparent)
    .width("100%")
    .height("100%")
  }

  @Builder
  private route(path: string) {
    if (this.routes[path] != undefined) {
      NavDestination() {
        Column() {
          this.routes[path].builder.builder()
        }
        .backgroundColor(Color.Transparent)
        .width("100%")
      }
      .padding({
        top: 8
      })
      .title(this.routes[path].title)
      .backgroundColor($r("app.color.rohy_background"))
      .width("100%")
      .hideToolBar(true)
      .mode(NavDestinationMode.STANDARD)
    }
  }

}
import { StrUtil } from '@pura/harmony-utils';
import { Markdown } from '@lidary/markdown';

@Component
export struct PrivacyPage {
  @Consume('settingsPageController')
  settingsPageController: NavPathStack
  @StorageLink('appColorMode')
  colorMode: string = "system";
  @State
  private privacy: string | undefined = undefined

  aboutToAppear(): void {
    getContext(this).resourceManager.getRawFileContent('privacy.md')
      .then((data) => {
        animateTo({
          duration: 200
        }, () => {
          this.privacy = StrUtil.unit8ArrayToStr(data)
        })
      })
  }

  build() {
    NavDestination() {
      Row() {
        Button({
          type: ButtonType.Circle
        }) {
          SymbolGlyph($r("sys.symbol.chevron_left"))
            .fontSize(24)
            .fontColor([$r("app.color.icon_primary")])
        }
        .onClick(() => {
          this.settingsPageController.pop()
        })
        .align(Alignment.Center)
        .margin({
          left: 12,
          top: 12
        })
        .width(40)
        .height(40)
        .backgroundColor($r("app.color.comp_background_tertiary"))

        Text("")
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r("app.color.font_primary"))
          .margin({
            left: 12,
            top: 12,
          })
        Blank()
          .layoutWeight(1)
      }
      .margin({
        left: 12,
        right: 12,
        top: 12
      })

      Column() {
        Blank()
          .height(20)
          .width("100%")
      }

      // 内容
      Column() {
        if (this.privacy != undefined) {
          List() {
            ListItem() {
              Markdown({
                content: this.privacy,
                fontStyle: {
                  fontColor: $r('app.color.font_primary')
                }
              })
            }
            .width("90%")

            ListItem() {
              Column() {
                Blank()
                  .height("120vp")
              }
            }
          }
          .alignListItem(ListItemAlign.Center)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          .width("100%")
          .height("100%")
        } else {
          Blank()
            .layoutWeight(2)
          LoadingProgress()
            .enableLoading(true)
            .color($r("app.color.icon_secondary"))
            .width(64)
            .height(64)
          Blank()
            .layoutWeight(3)
        }
      }
      .alignItems(HorizontalAlign.Center)
      .width("100%")
      .height("100%")
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.rohy_settings_background"))
  }
}
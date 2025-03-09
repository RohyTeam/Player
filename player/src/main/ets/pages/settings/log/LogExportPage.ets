import { Rlog } from "../../../log/Rlog"
import { SettingsDivider, SettingsGroup,
  SettingsHeader,
  SettingsPage, SettingsRow } from "../../components/SettingsPage"
import { curves, promptAction } from "@kit.ArkUI"

@Component
export struct LogExportPage {

  @Consume('settingsPageController')
  settingsPageController: NavPathStack

  @State
  private groupedLogs: Record<string, string[]> | undefined = undefined

  aboutToAppear(): void {
    Rlog.listGroupedLogs(getContext(this))
      .then((logs) => {
        animateTo({
          duration: 300
        }, () => {
          this.groupedLogs = logs
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

        Text($r('app.string.log_export'))
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
        if (this.groupedLogs != undefined) {
          Stack() {
            SettingsPage() {
              ForEach(Object.keys(this.groupedLogs), (group: string, index) => {
                SettingsHeader({
                  title: group
                })
                SettingsGroup() {
                  ForEach(this.groupedLogs![group], (log: string, index) => {
                    SettingsRow({
                      settingsTitle: log,
                      clickEvent: {
                        action: () => {
                          Rlog.exportLog(getContext(this), log)
                            .then((result) => {
                              if (result) {
                                promptAction.showToast({
                                  message: $r('app.string.log_export_success')
                                })
                              } else {
                                promptAction.showToast({
                                  message: $r('app.string.log_export_failed')
                                })
                              }
                            })
                        }
                      }
                    })
                    if ((this.groupedLogs![group]?.length || index + 1) - 1 > index) {
                      SettingsDivider()
                    }
                  })
                }
              })
            }
          }
          .width("100%")
          .height("100%")
          .animation({
            curve: curves.springMotion()
          })
          .visibility(this.groupedLogs != undefined ? Visibility.Visible : Visibility.Hidden)
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
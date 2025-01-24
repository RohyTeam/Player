export interface ClickEvent {

  action: () => void

}
export interface SwitchEvent {

  action: (value: boolean) => void

}

@Component
export struct SettingsPage {
  @BuilderParam
  content: () => void

  build() {
    List({ space: 12 }) {
      this.content()
    }
    .scrollBar(BarState.Off)
    .backgroundColor($r("app.color.rohy_settings_background"))
    .height("100%")
    .width("100%")
  }

}

@Component
export struct SettingsGroup {

  @BuilderParam
  content: () => void

  build() {
    ListItem() {
      Row() {
        Column() {
          this.content()
        }
      }
      .padding(4)
      .borderRadius(16)
      .backgroundColor($r("app.color.rohy_settings_card"))
      .width("90%")
    }
    .width("100%")
  }

}

@Component
export struct SettingsRow {

  @Prop
  @Require
  settingsTitle: ResourceStr
  @Prop
  @Require
  clickEvent: ClickEvent

  build() {
    Row() {
      Button() {
        Row() {
          Text(this.settingsTitle)
            .margin({
              left: 12
            })
            .fontColor($r("app.color.font_primary"))
          Blank()
            .layoutWeight(1)
        }
        .alignItems(VerticalAlign.Center)
      }
      .borderRadius(12)
      .onClick(() => {
        this.clickEvent.action()
      })
      .width("100%")
      .height("100%")
      .type(ButtonType.Normal)
      .backgroundColor($r("app.color.rohy_settings_card"))
    }
    .height("48vp")
    .width("100%")
  }

}

@Component
export struct SettingsSwitch {

  @Prop
  @Require
  settingsTitle: ResourceStr
  @Prop
  @Require
  switchEvent: SwitchEvent
  @Prop
  switchValue: boolean

  build() {
    Row() {
      Button() {
        Row() {
          Text(this.settingsTitle)
            .margin({
              left: 12
            })
            .fontColor($r("app.color.font_primary"))
          Blank()
            .layoutWeight(1)
          Toggle({
            type: ToggleType.Switch,
            isOn: this.switchValue
          })
            .margin({
              right: 12
            })
            .onChange((value) => {
              this.switchEvent.action(value)
            })
        }
        .alignItems(VerticalAlign.Center)
      }
      .borderRadius(12)
      .width("100%")
      .height("100%")
      .type(ButtonType.Normal)
      .backgroundColor($r("app.color.rohy_settings_card"))
    }
    .height("48vp")
    .width("100%")
  }

}

@Component
export struct SettingsDivider {

  build() {
    Divider()
      .margin({
        left: 12,
        right: 12
      })
  }

}
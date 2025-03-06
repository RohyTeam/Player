import { SegmentButton, SegmentButtonOptions } from '@ohos.arkui.advanced.SegmentButton'
import { SegmentButtonItemTuple, SegmentButtonTextItem } from '@kit.ArkUI'

export interface ClickEvent {

  action: () => void

}

export interface SwitchEvent {

  action: (value: boolean) => void

}

export interface SliderEvent {

  action: (value: number, mode: SliderChangeMode) => void

}

@Component
export struct SettingsPage {
  @BuilderParam
  content: () => void

  build() {
    List({ space: 12 }) {
      this.content()
      ListItem() {
        Column() {
          Blank()
            .height("120vp")
        }
      }
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
  settingsDesc: ResourceStr | undefined = undefined
  @Prop
  larger: boolean = false
  @Prop
  showGoToIcon: boolean = false
  @Prop
  @Require
  clickEvent: ClickEvent

  build() {
    Row() {
      Button() {
        Row() {
          Column() {
            Text(this.settingsTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r("app.color.font_primary"))
            if (this.settingsDesc != undefined) {
              Text(this.settingsDesc)
                .fontSize(14)
                .fontColor($r("app.color.font_secondary"))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({
            left: 12,
            top: 4,
            bottom: 4
          })
          Blank()
            .layoutWeight(1)
          if (this.showGoToIcon) {
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(20)
              .fontColor([$r('app.color.icon_primary')])
              .margin({
                right: 12
              })
          }
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
    .height(this.larger ? "56vp": "48vp")
    .width("100%")
  }
}

@Component
export struct SettingsSwitch {
  @Prop
  @Require
  settingsTitle: ResourceStr
  @Prop
  settingsDesc: ResourceStr | undefined = undefined
  @Prop
  settingsTips: ResourceStr | undefined = undefined
  @Prop
  larger: boolean = false
  @Prop
  @Require
  switchEvent: SwitchEvent
  @Prop
  switchValue: boolean
  @State
  showPopup: boolean = false

  @Builder
  popupText() {
    Column() {
      Text(this.settingsTips)
        .fontColor($r("app.color.font_primary"))
        .padding(16)
    }
    .constraintSize({
      maxWidth: "50%"
    })
  }

  build() {
    Row() {
      Button() {
        Row() {
          Column() {
            Text(this.settingsTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r("app.color.font_primary"))
            if (this.settingsDesc != undefined) {
              Text(this.settingsDesc)
                .fontSize(14)
                .fontColor($r("app.color.font_secondary"))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({
            left: 12,
            top: 4,
            bottom: 4
          })
          if (this.settingsTips != undefined) {
            SymbolGlyph($r('sys.symbol.questionmark_circle'))
              .fontSize(20)
              .fontColor([$r('app.color.icon_primary')])
              .onClick(() => {
                this.showPopup = true
              })
              .margin({
                left: 4
              })
              .bindPopup(
                this.showPopup,
                {
                  builder: this.popupText,
                  placement: Placement.Bottom,
                  enableArrow: true,
                  showInSubWindow: false,
                  popupColor: $r("app.color.rohy_settings_card"),
                  backgroundBlurStyle: BlurStyle.NONE,
                  onStateChange: (state) => {
                    if (!state.isVisible) {
                      this.showPopup = false
                    }
                  }
                }
              )
          }
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
              animateTo({
                duration: 200,
                curve: Curve.Linear,
                playMode: PlayMode.Normal
              }, () => {
                this.switchEvent.action(value)
              })
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
    .height(this.larger ? "56vp": "48vp")
    .width("100%")
  }
}

export interface SelectChoice {

  title: ResourceStr
  onSwitch: () => void

}

@Component
export struct SettingsSelection {
  @Prop
  @Require
  settingsTitle: ResourceStr
  @Prop
  settingsDesc: ResourceStr | undefined = undefined
  @Prop
  settingsTips: ResourceStr | undefined = undefined
  @Prop
  larger: boolean = false
  @Prop
  blankSize: number = 2
  @Prop
  dropdownStyle: boolean = false
  @Prop
  @Require
  choices: SelectChoice[]
  @Prop
  @Require
  selectedButton: number = 0
  @State
  selectedButtons: number[] = [this.selectedButton]
  @State
  segmentOptions: SegmentButtonOptions | undefined = undefined
  @State
  selectOptions: SelectOption[] | undefined = undefined
  @State
  showPopup: boolean = false
  @State
  private selectedText: ResourceStr = this.choices[this.selectedButton].title

  @Builder
  popupText() {
    Column() {
      Text(this.settingsTips)
        .fontColor($r("app.color.font_primary"))
        .padding(16)
    }
    .constraintSize({
      maxWidth: "50%"
    })
  }

  aboutToAppear(): void {
    let buttonItems: SegmentButtonTextItem[] = []
    for (let choice of this.choices) {
      let buttonItem: SegmentButtonTextItem = {
        text: choice.title
      }
      buttonItems.push(buttonItem)
    }
    this.segmentOptions = SegmentButtonOptions.capsule({
      buttons: buttonItems as SegmentButtonItemTuple,
      multiply: false,
      backgroundBlurStyle: BlurStyle.BACKGROUND_THICK,
    })
    this.selectOptions = this.choices.map(choice => {
      return {
        value: choice.title
      } as SelectOption
    })
  }

  build() {
    Row() {
      Button() {
        Row() {
          Column() {
            Text(this.settingsTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r("app.color.font_primary"))
            if (this.settingsDesc != undefined) {
              Text(this.settingsDesc)
                .fontSize(14)
                .fontColor($r("app.color.font_secondary"))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({
            left: 12,
            top: 4,
            bottom: 4
          })
          if (this.settingsTips != undefined) {
            SymbolGlyph($r('sys.symbol.questionmark_circle'))
              .fontSize(20)
              .fontColor([$r('app.color.icon_primary')])
              .onClick(() => {
                this.showPopup = true
              })
              .margin({
                left: 4
              })
              .bindPopup(
                this.showPopup,
                {
                  builder: this.popupText,
                  placement: Placement.Bottom,
                  enableArrow: true,
                  showInSubWindow: false,
                  popupColor: $r("app.color.rohy_settings_card"),
                  backgroundBlurStyle: BlurStyle.NONE,
                  onStateChange: (state) => {
                    if (!state.isVisible) {
                      this.showPopup = false
                    }
                  }
                }
              )
          }
          if (this.dropdownStyle) {
            Blank()
              .layoutWeight(1)
            Select(this.selectOptions)
              .value(this.selectedText)
              .selected(this.selectedButton)
              .fontColor($r("app.color.font_primary"))
              .space(8)
              .arrowPosition(ArrowPosition.END)
              .menuAlign(MenuAlignType.START)
              .onSelect((index) => {
                this.selectedText = this.choices[index].title
                this.selectedButton = index
                this.choices[index].onSwitch()
              })
              .margin({
                right: 12
              })
          } else {
            Blank()
              .layoutWeight(this.blankSize)
            SegmentButton({
              options: this.segmentOptions,
              selectedIndexes: this.selectedButtons,
              onItemClicked: (index) => {
                animateTo({
                  duration: 200,
                  curve: Curve.Linear,
                  playMode: PlayMode.Normal
                }, () => {
                  this.selectedText = this.choices[index].title
                  this.choices[index].onSwitch()
                })
              }
            })
              .layoutWeight(3)
              .margin({
                right: 12
              })
          }
        }
        .alignItems(VerticalAlign.Center)
      }
      .borderRadius(12)
      .width("100%")
      .height("100%")
      .type(ButtonType.Normal)
      .backgroundColor($r("app.color.rohy_settings_card"))
    }
    .height(this.larger ? "56vp": "48vp")
    .width("100%")
  }
}

@Component
export struct SettingsSelectionSpecificForToolbarCustomizer {
  @Prop
  @Require
  settingsTitle: ResourceStr
  @Prop
  settingsDesc: ResourceStr | undefined = undefined
  @Prop
  settingsTips: ResourceStr | undefined = undefined
  @Prop
  larger: boolean = false
  @Link
  topBarBlurType: number
  @Link
  bottomBarBlurType: number
  @Link
  syncBlurType: number
  @Link
  topBar: boolean
  @Link
  separate: boolean
  @Prop
  @Require
  choices: SelectChoice[]
  @State
  segmentOptions: SegmentButtonOptions | undefined = undefined
  @State
  selectOptions: SelectOption[] | undefined = undefined
  @State
  showPopup: boolean = false

  private getSelectedText(): ResourceStr {
    return this.choices[this.getSelectedOption()].title
  }

  private getSelectedOption(): number {
    if (this.separate) {
      if (this.topBar) {
        return this.topBarBlurType
      } else {
        return this.bottomBarBlurType
      }
    } else {
      return this.syncBlurType
    }
  }

  @Builder
  popupText() {
    Column() {
      Text(this.settingsTips)
        .fontColor($r("app.color.font_primary"))
        .padding(16)
    }
    .constraintSize({
      maxWidth: "50%"
    })
  }

  aboutToAppear(): void {
    let buttonItems: SegmentButtonTextItem[] = []
    for (let choice of this.choices) {
      let buttonItem: SegmentButtonTextItem = {
        text: choice.title
      }
      buttonItems.push(buttonItem)
    }
    this.segmentOptions = SegmentButtonOptions.capsule({
      buttons: buttonItems as SegmentButtonItemTuple,
      multiply: false,
      backgroundBlurStyle: BlurStyle.BACKGROUND_THICK,
    })
    this.selectOptions = this.choices.map(choice => {
      return {
        value: choice.title
      } as SelectOption
    })
  }

  build() {
    Row() {
      Button() {
        Row() {
          Column() {
            Text(this.settingsTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r("app.color.font_primary"))
            if (this.settingsDesc != undefined) {
              Text(this.settingsDesc)
                .fontSize(14)
                .fontColor($r("app.color.font_secondary"))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({
            left: 12,
            top: 4,
            bottom: 4
          })
          if (this.settingsTips != undefined) {
            SymbolGlyph($r('sys.symbol.questionmark_circle'))
              .fontSize(20)
              .fontColor([$r('app.color.icon_primary')])
              .onClick(() => {
                this.showPopup = true
              })
              .margin({
                left: 4
              })
              .bindPopup(
                this.showPopup,
                {
                  builder: this.popupText,
                  placement: Placement.Bottom,
                  enableArrow: true,
                  showInSubWindow: false,
                  popupColor: $r("app.color.rohy_settings_card"),
                  backgroundBlurStyle: BlurStyle.NONE,
                  onStateChange: (state) => {
                    if (!state.isVisible) {
                      this.showPopup = false
                    }
                  }
                }
              )
          }
          Blank()
            .layoutWeight(1)
          Select(this.selectOptions)
            .value(this.getSelectedText())
            .selected(this.getSelectedOption())
            .fontColor($r("app.color.font_primary"))
            .space(8)
            .arrowPosition(ArrowPosition.END)
            .menuAlign(MenuAlignType.START)
            .onSelect((index) => {
              this.choices[index].onSwitch()
            })
            .margin({
              right: 12
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
    .height(this.larger ? "56vp": "48vp")
    .width("100%")
  }
}

@Component
export struct SettingsSlider {
  @Prop
  @Require
  settingsTitle: ResourceStr
  @Prop
  settingsDesc: ResourceStr | undefined = undefined
  @Prop
  settingsTips: ResourceStr | undefined = undefined
  @Prop
  larger: boolean = false
  @Prop
  @Require
  sliderOptions: SliderOptions
  @Prop
  showSteps: boolean = false
  @Prop
  @Require
  sliderEvent: SliderEvent
  @State
  showPopup: boolean = false

  @Builder
  popupText() {
    Column() {
      Text(this.settingsTips)
        .fontColor($r("app.color.font_primary"))
        .padding(16)
    }
    .constraintSize({
      maxWidth: "50%"
    })
  }

  build() {
    Row() {
      Button() {
        Row() {
          Column() {
            Text(this.settingsTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r("app.color.font_primary"))
            if (this.settingsDesc != undefined) {
              Text(this.settingsDesc)
                .fontSize(14)
                .fontColor($r("app.color.font_secondary"))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .margin({
            left: 12,
            top: 4,
            bottom: 4
          })
          if (this.settingsTips != undefined) {
            SymbolGlyph($r('sys.symbol.questionmark_circle'))
              .fontSize(20)
              .fontColor([$r('app.color.icon_primary')])
              .onClick(() => {
                this.showPopup = true
              })
              .margin({
                left: 4
              })
              .bindPopup(
                this.showPopup,
                {
                  builder: this.popupText,
                  placement: Placement.Bottom,
                  enableArrow: true,
                  showInSubWindow: false,
                  popupColor: $r("app.color.rohy_settings_card"),
                  backgroundBlurStyle: BlurStyle.NONE,
                  onStateChange: (state) => {
                    if (!state.isVisible) {
                      this.showPopup = false
                    }
                  }
                }
              )
          }
          Blank()
            .layoutWeight(2)
          Slider(this.sliderOptions)
            .showSteps(this.showSteps)
            .onChange((value: number, mode: SliderChangeMode) => {
              this.sliderEvent.action(value, mode)
            })
            .width('50%')
            .margin({
              right: 4
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
    .height(this.larger ? "56vp": "48vp")
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
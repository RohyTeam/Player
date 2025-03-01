import { PreferencesUtil } from '@pura/harmony-utils'
import { StyleConstants } from '../../common/constants/StyleConstants'
import { bottomBarOptions, topBarOptions } from '../../util/ToolbarCustomizationUtil'
import { DraggableCustomization } from '../components/DraggableCustomization'
import {
  SelectChoice,
  SettingsDivider,
  SettingsGroup,
  SettingsSelection,
  SettingsSelectionSpecificForToolbarCustomizer,
  SettingsSlider,
  SettingsSwitch
} from '../components/SettingsPage'

// TODO：横竖屏不同排布

@Component
export struct ToolbarButtonsLandscapeCustomizer { // 横屏使用

  @Consume('settingsPageController')
  settingsPageController: NavPathStack
  @State
  private topBarSelected: number[] = []
  @State
  private bottomBarSelected: number[] = []
  @State
  private topBar: boolean = true
  @State
  private separate: boolean = false
  @State
  private syncBarBlur: number = 0
  @State
  private syncBarBlurType: number = 0
  @State
  private syncBarOpacity: number = 100
  @State
  private topBarBlur: number = 0
  @State
  private topBarBlurType: number = 0
  @State
  private topBarOpacity: number = 100
  @State
  private bottomBarBlur: number = 0
  @State
  private bottomBarBlurType: number = 0
  @State
  private bottomBarOpacity: number = 100
  @StorageLink('appColorMode')
  colorMode: string = "system";
  private blurTypeOptions: SelectChoice[] = [
    {
      title: $r('app.string.blurtype_none'),
      onSwitch: () => {
        if (this.separate) {
          if (this.topBar) {
            this.topBarBlurType = 0
            PreferencesUtil.putSync('toolbar_topbar_blurtype', 0)
          } else {
            this.bottomBarBlurType = 0
            PreferencesUtil.putSync('toolbar_bottombar_blur', 0)
          }
        } else {
          this.syncBarBlurType = 0
          PreferencesUtil.putSync('toolbar_sync_blurtype', 0)
        }
      }
    },
    {
      title: $r('app.string.blurtype_ultrathin'),
      onSwitch: () => {
        if (this.separate) {
          if (this.topBar) {
            this.topBarBlurType = 1
            PreferencesUtil.putSync('toolbar_topbar_blurtype', 1)
          } else {
            this.bottomBarBlurType = 1
            PreferencesUtil.putSync('toolbar_bottombar_blur', 1)
          }
        } else {
          this.syncBarBlurType = 1
          PreferencesUtil.putSync('toolbar_sync_blurtype', 1)
        }
      }
    },
    {
      title: $r('app.string.blurtype_thin'),
      onSwitch: () => {
        if (this.separate) {
          if (this.topBar) {
            this.topBarBlurType = 2
            PreferencesUtil.putSync('toolbar_topbar_blurtype', 2)
          } else {
            this.bottomBarBlurType = 2
            PreferencesUtil.putSync('toolbar_bottombar_blur', 2)
          }
        } else {
          this.syncBarBlurType = 2
          PreferencesUtil.putSync('toolbar_sync_blurtype', 2)
        }
      }
    },
    {
      title: $r('app.string.blurtype_regular'),
      onSwitch: () => {
        if (this.separate) {
          if (this.topBar) {
            this.topBarBlurType = 3
            PreferencesUtil.putSync('toolbar_topbar_blurtype', 3)
          } else {
            this.bottomBarBlurType = 3
            PreferencesUtil.putSync('toolbar_bottombar_blur', 3)
          }
        } else {
          this.syncBarBlurType = 3
          PreferencesUtil.putSync('toolbar_sync_blurtype', 3)
        }
      }
    },
    {
      title: $r('app.string.blurtype_thick'),
      onSwitch: () => {
        if (this.separate) {
          if (this.topBar) {
            this.topBarBlurType = 4
            PreferencesUtil.putSync('toolbar_topbar_blurtype', 4)
          } else {
            this.bottomBarBlurType = 4
            PreferencesUtil.putSync('toolbar_bottombar_blur', 4)
          }
        } else {
          this.syncBarBlurType = 4
          PreferencesUtil.putSync('toolbar_sync_blurtype', 4)
        }
      }
    },
    {
      title: $r('app.string.blurtype_ultrathick'),
      onSwitch: () => {
        if (this.separate) {
          if (this.topBar) {
            this.topBarBlurType = 5
            PreferencesUtil.putSync('toolbar_topbar_blurtype', 5)
          } else {
            this.bottomBarBlurType = 5
            PreferencesUtil.putSync('toolbar_bottombar_blur', 5)
          }
        } else {
          this.syncBarBlurType = 5
          PreferencesUtil.putSync('toolbar_sync_blurtype', 5)
        }
      }
    }
  ]

  aboutToAppear(): void {
    { // 顶栏
      let selected = PreferencesUtil.getStringSync('toolbar_landscape_topbar', '')
      if (selected.length > 0) {
        if (selected.indexOf(',') > 0) {
          this.topBarSelected = selected.split(',').map((value) => parseInt(value))
        } else {
          this.topBarSelected = [parseInt(selected)]
        }
      }
      this.topBarBlur = PreferencesUtil.getNumberSync('toolbar_topbar_blur', 0)
      this.topBarBlurType = PreferencesUtil.getNumberSync('toolbar_topbar_blurtype', 0)
      if (this.topBarBlurType > 5) {
        this.topBarBlurType = 0
        PreferencesUtil.putSync('toolbar_topbar_blurtype', 0)
      }
      this.topBarOpacity = PreferencesUtil.getNumberSync('toolbar_topbar_opacity', 100)
    }
    { // 底栏
      let selected = PreferencesUtil.getStringSync('toolbar_landscape_bottombar', '')
      if (selected.length > 0) {
        if (selected.indexOf(',') > 0) {
          this.bottomBarSelected = selected.split(',').map((value) => parseInt(value))
        } else {
          this.bottomBarSelected = [parseInt(selected)]
        }
      }
      this.bottomBarBlur = PreferencesUtil.getNumberSync('toolbar_bottombar_blur', 0)
      this.bottomBarBlurType = PreferencesUtil.getNumberSync('toolbar_bottombar_blurtype', 0)
      if (this.bottomBarBlurType > 5) {
        this.bottomBarBlurType = 0
        PreferencesUtil.putSync('toolbar_bottombar_blurtype', 0)
      }
      this.bottomBarOpacity = PreferencesUtil.getNumberSync('toolbar_bottombar_opacity', 100)
    }
    this.separate = PreferencesUtil.getBooleanSync('toolbar_separated', false)
    this.syncBarBlur = PreferencesUtil.getNumberSync('toolbar_sync_blur', 0)
    this.syncBarBlurType = PreferencesUtil.getNumberSync('toolbar_sync_blurtype', 0)
    if (this.syncBarBlurType > 5) {
      this.syncBarBlurType = 0
      PreferencesUtil.putSync('toolbar_sync_blurtype', 0)
    }
    this.syncBarOpacity = PreferencesUtil.getNumberSync('toolbar_sync_opacity', 100)
  }

  @Builder
  private options() {
    SettingsGroup() {
      SettingsSwitch({
        settingsTitle: $r('app.string.toolbar_split_property'),
        switchValue: !this.separate,
        switchEvent: {
          action: (value: boolean) => {
            this.separate = !value
            PreferencesUtil.putSync('toolbar_separated', !value)
          }
        }
      })
      if (this.separate) {
        SettingsDivider()
        SettingsSelection({
          settingsTitle: $r("app.string.controller_bar"),
          blankSize: 3,
          choices: [
            {
              title: $r('app.string.settings_toolbar_topbar'),
              onSwitch: () => {
                this.topBar = true
              }
            },
            {
              title: $r('app.string.settings_toolbar_bottombar'),
              onSwitch: () => {
                this.topBar = false
              }
            }
          ],
          selectedButton: this.topBar ? 0 : 1
        })
      }
      SettingsDivider()
      SettingsSlider({
        settingsTitle: $r("app.string.opacity"),
        sliderOptions: {
          min: 0,
          max: 90,
          step: 1,
          style: SliderStyle.InSet,
          value: this.separate ? (this.topBar ? (this.topBarOpacity - 10) : (this.bottomBarOpacity - 10)) :
          this.syncBarOpacity
        },
        sliderEvent: {
          action: (value: number, mode: SliderChangeMode) => {
            if (this.separate) {
              if (this.topBar) {
                this.topBarOpacity = value + 10
                PreferencesUtil.putSync('toolbar_topbar_opacity', value + 10)
              } else {
                this.bottomBarOpacity = value + 10
                PreferencesUtil.putSync('toolbar_bottombar_opacity', value + 10)
              }
            } else {
              this.syncBarOpacity = value + 10
              PreferencesUtil.putSync('toolbar_sync_opacity', value + 10)
            }
          }
        }
      })
      SettingsDivider()
      SettingsSelectionSpecificForToolbarCustomizer({
        settingsTitle: $r("app.string.blurtype"),
        choices: this.blurTypeOptions,
        separate: this.separate,
        topBar: this.topBar,
        topBarBlurType: this.topBarBlurType,
        bottomBarBlurType: this.bottomBarBlurType,
        syncBlurType: this.syncBarBlurType
      })
      SettingsDivider()
      SettingsSlider({
        settingsTitle: $r("app.string.blur"),
        sliderOptions: {
          min: 0,
          max: 100,
          style: SliderStyle.InSet,
          value: this.separate ? (this.topBar ? this.topBarBlur : this.bottomBarBlur) : this.syncBarBlur
        },
        sliderEvent: {
          action: (value: number, mode: SliderChangeMode) => {
            if (this.separate) {
              if (this.topBar) {
                this.topBarBlur = value
                PreferencesUtil.putSync('toolbar_topbar_blur', value)
              } else {
                this.bottomBarBlur = value
                PreferencesUtil.putSync('toolbar_bottombar_blur', value)
              }
            } else {
              this.syncBarBlur = value
              PreferencesUtil.putSync('toolbar_sync_blur', value)
            }
          }
        }
      })
    }
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

        Text($r('app.string.settings_toolbar'))
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

      List({ space: 12 }) {
        ListItem() {
          Stack() {
            Row() {
              // 用于展示模糊效果
              Column()
                .backgroundColor(Color.Red)
                .height("100%")
                .layoutWeight(1)
              Column()
                .backgroundColor(Color.Orange)
                .height("100%")
                .layoutWeight(1)
              Column()
                .backgroundColor(Color.Yellow)
                .height("100%")
                .layoutWeight(1)
              Column()
                .backgroundColor(Color.Green)
                .height("100%")
                .layoutWeight(1)
              Column()
                .backgroundColor("#00ffff")
                .height("100%")
                .layoutWeight(1)
              Column()
                .backgroundColor(Color.Blue)
                .height("100%")
                .layoutWeight(1)
              Column()
                .backgroundColor("#ff00ff")
                .height("100%")
                .layoutWeight(1)
            }
            .clip(true)
            .borderRadius(16)
            .height("100%")
            .width("100%")

            Column() {
              if (this.topBar || !this.separate) {
                Row() {

                }
                .opacity(Math.min(Math.max(0.1, (this.separate ? this.topBarOpacity : this.syncBarOpacity) / 100), 1.0))
                .foregroundBlurStyle(
                  StyleConstants.BLUR[this.separate ? this.topBarBlurType : this.syncBarBlurType],
                  {
                    scale: Math.max(0, Math.min(1, (this.separate ? this.topBarBlur : this.syncBarBlur) / 100))
                  }
                )
                .height('25%')
                .width("100%")
                .backgroundColor(Color.White)
                .borderRadius(16)
              }
              Blank()
                .layoutWeight(1)
                .backgroundColor(Color.Transparent)
              if (!this.topBar || !this.separate) {
                Row() {

                }
                .opacity(Math.min(Math.max(0.1, (this.separate ? this.bottomBarOpacity : this.syncBarOpacity) / 100),
                  1.0))
                .foregroundBlurStyle(
                  StyleConstants.BLUR[this.separate ? this.bottomBarBlurType : this.syncBarBlurType],
                  {
                    scale: Math.max(0, Math.min(1, (this.separate ? this.bottomBarBlur : this.syncBarBlur) / 100))
                  }
                )
                .height('25%')
                .width("100%")
                .backgroundColor(Color.White)
                .borderRadius(16)
              }
            }
            .backgroundColor(Color.Transparent)
            .height("100%")
            .width("100%")
          }
          .borderRadius(16)
          .backgroundColor(Color.Black)
          .width("90%")
          .aspectRatio(16 / 9)
        }
        .width("100%")

        this.options()
        ListItem() {
          DraggableCustomization({
            title: $r('app.string.settings_toolbar_topbar'),
            options: topBarOptions,
            selected: this.topBarSelected,
            functions: {
              onChange: (selected: number[], unselected: number[]) => {
                this.topBarSelected = selected
                if (selected.length > 0) {
                  PreferencesUtil.putSync('toolbar_landscape_topbar', selected.join(','))
                } else {
                  PreferencesUtil.putSync('toolbar_landscape_topbar', '')
                }
              }
            }
          })
        }

        ListItem() {
          DraggableCustomization({
            title: $r('app.string.settings_toolbar_bottombar'),
            options: bottomBarOptions,
            selected: this.bottomBarSelected,
            functions: {
              onChange: (selected: number[], unselected: number[]) => {
                this.bottomBarSelected = selected
                if (selected.length > 0) {
                  PreferencesUtil.putSync('toolbar_landscape_bottombar', selected.join(','))
                } else {
                  PreferencesUtil.putSync('toolbar_landscape_bottombar', '')
                }
              }
            }
          })
        }

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
    .hideTitleBar(true)
    .hideToolBar(true)
    .width("100%")
    .height("100%")
    .backgroundColor($r("app.color.rohy_settings_background"))
  }
}

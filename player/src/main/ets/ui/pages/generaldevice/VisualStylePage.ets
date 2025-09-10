import { blurStyleToNumber, Pref } from '../../../context/PreferenceContext'
import { Sys } from '../../../context/SystemContext'
import { ChapterInfo } from '../../../player/chapter/ChapterInfo'
import { convertNumberToDurationString } from '../../../utils/NumberUtils'
import { Modifiers } from '../../attributemodifier/Modifiers'
import { CircleIconButton } from '../../button/CircleIconButton'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { WindowManager } from '../../manager/WindowManager'
import { curves, window } from '@kit.ArkUI'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerSwitch } from '../../component/inner/InnerSwitch'
import { InnerDivider } from '../../component/inner/InnerDivider'
import { InnerSegment } from '../../component/inner/InnerSegment'
import { InnerSlider } from '../../component/inner/InnerSlider'
import { keepNumber } from '../../../utils/MathUtils'
import { InnerCounter } from '../../component/inner/InnerCounter'

@ComponentV2
export struct VisualStylePage {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    WindowManager.setStatusBar(this.getUIContext(), false)
    WindowManager.setNavigationIndicator(this.getUIContext(), false)
    if (!Sys.isTablet()) {
      WindowManager.setOrientation(this.getUIContext(), window.Orientation.AUTO_ROTATION_LANDSCAPE)
    }
  }

  aboutToDisappear(): void {
    WindowManager.setStatusBar(this.getUIContext(), true)
    WindowManager.setNavigationIndicator(this.getUIContext(), true)
    if (!Sys.isTablet()) {
      WindowManager.setOrientation(this.getUIContext(), window.Orientation.PORTRAIT)
    }
  }

  @Builder
  actualBuild() {
    Row() {
      Blank()
        .layoutWeight(1)
      Column() {
        InnerContainer({
          bgColor: Color.Transparent,
          edgeEffect: false
        }) {
          InnerComponentSet() {
            InnerSwitch({
              title: $r("app.string.ui_update"),
              initialValue: Pref.uiUpdatePreview,
              switch: (original) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  Pref.uiUpdatePreview = !original
                })
                return !original
              }
            })
            InnerDivider()
            InnerSegment({
              title: $r('app.string.blur_style'),
              initialSelected: blurStyleToNumber(Pref.blurStyle),
              choices: [
                {
                  title: $r('app.string.blur_style_thin'),
                  action: () => {
                    animateTo({
                      duration: 200,
                      curve: curves.springMotion()
                    }, () => {
                      Pref.blurStyle = BlurStyle.Thin
                    })
                  }
                },
                {
                  title: $r('app.string.blur_style_regular'),
                  action: () => {
                    animateTo({
                      duration: 200,
                      curve: curves.springMotion()
                    }, () => {
                      Pref.blurStyle = BlurStyle.Regular
                    })
                  }
                },
                {
                  title: $r('app.string.blur_style_thick'),
                  action: () => {
                    animateTo({
                      duration: 200,
                      curve: curves.springMotion()
                    }, () => {
                      Pref.blurStyle = BlurStyle.Thick
                    })
                  }
                }
              ]
            })
            InnerDivider()
            InnerSlider({
              title: $r('app.string.blur_level', `${keepNumber(Math.round(Pref.blurLevel * 10) / 10, 1)}`),
              quickUpdate: true,
              min: 0,
              max: 1,
              step: 0.1,
              showSteps: true,
              initialValue: Pref.blurLevel,
              onChange: (value) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  Pref.blurLevel = value
                })
                return true
              }
            })
          }
        }
      }
      .layoutWeight(8)

      Blank()
        .layoutWeight(1)
      Column() {
        InnerContainer({
          bgColor: Color.Transparent,
          edgeEffect: false
        }) {
          InnerComponentSet() {
            InnerSwitch({
              title: $r("app.string.use_display_test_image"),
              initialValue: this.useDisplayTestImage,
              switch: (original) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  this.useDisplayTestImage = !original
                })
                return !original
              }
            })
            InnerDivider()
            InnerCounter({
              title: $r('app.string.inner_cornor_radius'),
              min: 0,
              max: 64,
              initialValue: Pref.innerRadius,
              gestureAlwaysAnnouncement: true,
              onChange: (value) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  Pref.innerRadius = value
                })
              }
            })
            if (Pref.uiUpdatePreview) {
              InnerDivider()
              InnerCounter({
                title: $r('app.string.outer_cornor_radius'),
                min: 0,
                max: 64,
                initialValue: Pref.outerRadius,
                gestureAlwaysAnnouncement: true,
                onChange: (value) => {
                  animateTo({
                    duration: 200,
                    curve: curves.springMotion()
                  }, () => {
                    Pref.outerRadius = value
                  })
                }
              })
                .transition(
                  TransitionEffect.scale({
                    y: 0,
                    centerY: 0
                  })
                    .combine(TransitionEffect.OPACITY)
                )
            }
          }
        }
      }
      .layoutWeight(8)

      Blank()
        .layoutWeight(1)
    }
    .layoutWeight(1)
    .width("100%")
  }

  @Local
  private useDisplayTestImage: boolean = false
  @Local
  private currentPosition: number = ((12 * 60) + 34) * 1000
  private maxDuration: number = ((23 * 60) + 33) * 1000

  private chapters(): ChapterInfo[] {
    return [
      {
        title: "chapter 1",
        start: 0,
        end: 30 * 1000
      },
      {
        title: $r("app.string.untitled"),
        start: 30 * 1000,
        end: ((6 * 60) + 12) * 1000,
      },
      {
        title: $r("app.string.untitled"),
        start: ((6 * 60) + 12) * 1000,
        end: ((12 * 60) + 23) * 1000,
      },
      {
        title: $r("app.string.untitled"),
        start: ((12 * 60) + 23) * 1000,
        end: ((23 * 60) + 33) * 1000
      }
    ]
  }

  build() {
    NavDestination() {
      Stack() {
        if (this.useDisplayTestImage) {
          Image($r('app.media.display_test'))
            .objectFit(ImageFit.Fill)
            .width("100%")
            .height("100%")
        }

        Column() {
          Row() {
            Column() {
              Row() {
                CircleIconButton({
                  icon: $r("sys.symbol.chevron_left"),
                  buttonMargin: {
                    left: 16,
                    top: 12,
                    bottom: 12
                  },
                  clickCallback: () => {
                    this.indexNavigator.pop()
                  }
                })
                Text($r("app.string.visual_style"))
                  .maxLines(1)
                  .textOverflow({
                    overflow: TextOverflow.MARQUEE
                  })
                  .margin({
                    left: 4,
                    right: 4
                  })
                  .layoutWeight(3)
                  .fontColor($r("sys.color.font_primary"))
                Blank()
                  .layoutWeight(1)
                CircleIconButton({
                  icon: $r("sys.symbol.bookmark"),
                  buttonMargin: {
                    right: 16,
                    top: 12,
                    bottom: 12
                  },
                })
              }
              .alignItems(VerticalAlign.Center)
              .width("100%")
            }
            .borderRadius(
              Pref.uiUpdatePreview ? {
                topLeft: Pref.outerRadius,
                topRight: Pref.outerRadius,
                bottomLeft: Pref.innerRadius,
                bottomRight: Pref.innerRadius
              } : {
                bottomLeft: Pref.innerRadius,
                bottomRight: Pref.innerRadius
              }
            )
            .margin(
              Pref.uiUpdatePreview ? {
                top: 8,
                left: 8,
                right: 8
              } : 0
            )
            .layoutWeight(1)
            .attributeModifier(Modifiers.backgroundBlur())
          }
          .width("100%")

          this.actualBuild()
          Row() {
            Column() {
              Row() {
                Text(`${convertNumberToDurationString(this.currentPosition)}`)
                  .margin({
                    left: 16,
                    right: 4
                  })
                  .fontColor($r("sys.color.font_secondary"))
                Stack() {
                  Slider({
                    min: 0,
                    max: this.maxDuration,
                    step: 1,
                    value: this.currentPosition
                  })
                    .enabled(false)
                    .blockSize({
                      width: 1,
                      height: 1
                    })
                    .blockColor(Color.Transparent)
                    .blockBorderColor(Color.Transparent)
                    .width("100%")
                  Column() {
                    Stack() {
                      ForEach(this.chapters(), (chapter: ChapterInfo) => {
                        Row() {
                          Blank()
                            .layoutWeight(chapter.start)
                          SymbolGlyph($r('sys.symbol.bookmark_fill'))
                            .fontColor([$r('sys.color.icon_primary')])
                            .fontSize(8)
                            .width(8)
                            .height(8)
                          Blank()
                            .layoutWeight(chapter.end - chapter.start)
                          SymbolGlyph($r('sys.symbol.bookmark_fill'))
                            .fontColor([$r('sys.color.icon_primary')])
                            .fontSize(8)
                            .width(8)
                            .height(8)
                            .visibility(Visibility.Hidden)
                          Blank()
                            .layoutWeight(this.maxDuration - chapter.end)
                        }
                        .width("100%")
                      })
                    }
                    .width("100%")
                  }
                  .width("100%")

                  Slider({
                    min: 0,
                    max: this.maxDuration,
                    step: 1,
                    value: this.currentPosition
                  })
                    .trackColor(Color.Transparent)
                    .selectedColor(Color.Transparent)
                    .stepColor(Color.Transparent)
                    .width("100%")
                    .onChange((value) => {
                      this.currentPosition = value
                    })
                }
                .layoutWeight(1)

                Text(`${convertNumberToDurationString(this.maxDuration)}`)
                  .margin({
                    left: 4,
                    right: 16
                  })
                  .fontColor($r("sys.color.font_secondary"))
              }
              .width("100%")

              Row() {
                CircleIconButton({
                  icon: $r("sys.symbol.gobackward_15"),
                  buttonMargin: {
                    left: 16,
                    bottom: 12
                  }
                })
                CircleIconButton({
                  icon: $r("sys.symbol.play_fill"),
                  buttonMargin: {
                    left: 12,
                    bottom: 12
                  }
                })
                CircleIconButton({
                  icon: $r("sys.symbol.goforward_15"),
                  buttonMargin: {
                    left: 12,
                    bottom: 12
                  }
                })
                Blank()
                  .layoutWeight(1)
                CircleIconButton({
                  icon: $r("sys.symbol.questionmark_circle"),
                  buttonMargin: {
                    right: 16,
                    bottom: 12
                  },
                })
                CircleIconButton({
                  icon: $r("sys.symbol.questionmark_circle"),
                  buttonMargin: {
                    right: 16,
                    bottom: 12
                  }
                })
                CircleIconButton({
                  icon: $r("sys.symbol.chevron_left_2"),
                  buttonMargin: {
                    right: 16,
                    bottom: 12
                  },
                  iconRotation: 180
                })
              }
              .width("100%")
            }
            .borderRadius(
              Pref.uiUpdatePreview ? {
                topLeft: Pref.innerRadius,
                topRight: Pref.innerRadius,
                bottomLeft: Pref.outerRadius,
                bottomRight: Pref.outerRadius
              } : {
                topLeft: Pref.innerRadius,
                topRight: Pref.innerRadius
              }
            )
            .margin(
              Pref.uiUpdatePreview ? {
                bottom: 8,
                left: 8,
                right: 8
              } : 0
            )
            .layoutWeight(1)
            .attributeModifier(Modifiers.backgroundBlur())
          }
          .width("100%")
        }
        .backgroundColor(Color.Transparent)
        .height("100%")
        .width("100%")
      }
      .width("100%")
      .height("100%")
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
    .backgroundColor(Color.Black)
  }
}
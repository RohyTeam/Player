import { Pref } from "../../../../context/PreferenceContext";
import { InnerComponentSet } from "../../../component/inner/InnerComponentSet";
import { InnerContainer } from "../../../component/inner/InnerContainer";
import { InnerContainerDivider } from "../../../component/inner/InnerContainerDivider";
import { InnerSwitch } from "../../../component/inner/InnerSwitch";
import { curves } from "@kit.ArkUI";
import { CircleIconButton } from "../../../button/CircleIconButton";
import { convertNumberToDurationString } from "../../../../utils/NumberUtils";
import { Modifiers } from "../../../attributemodifier/Modifiers";
import { ChapterInfo } from "../../../../player/chapter/ChapterInfo";
import { InnerDivider } from "../../../component/inner/InnerDivider";
import { InnerCounter } from "../../../component/inner/InnerCounter";
import { InnerDraggableArea, InnerDraggableContainer } from "../../../component/inner/InnerDraggable";
import { InnerContainerText } from "../../../component/inner/InnerContainerText";
import { indexToDraggableItem, listHidButtons } from "../../../player/controller/ControllerItemMappings";
import { Con } from "../../../../context/ControllerContext";
import { Sys } from "../../../../context/SystemContext";

@ComponentV2
export struct AppearancePage {

  @Provider("useDisplayTestImage")
  private useDisplayTestImage: boolean = false

  @Provider("whiteBackground")
  private whiteBackground: boolean = false

  @Local
  private hidePreview: boolean = false

  build() {
    Column() {
      FakePlayerPreview()
        .visibility(this.hidePreview ? Visibility.None : Visibility.Visible)
        .transition(
          TransitionEffect.scale({
            y: 0,
            centerY: 0
          }).combine(TransitionEffect.OPACITY)
        )
      CircleIconButton({
        icon: $r('sys.symbol.chevron_down'),
        iconRotation: this.hidePreview ? 0 : 180,
        clickCallback: () => {
          animateTo({
            duration: 200,
            curve: curves.springMotion()
          }, () => {
            this.hidePreview = !this.hidePreview
          })
        }
      })
        .margin({
          top: this.hidePreview ? 8 : 0,
          bottom: 8
        })
      Column() {
        InnerContainer({
          bgColor: Color.Transparent
        }) {
          InnerContainerDivider()
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
            InnerSwitch({
              title: $r("app.string.use_white_background"),
              initialValue: this.whiteBackground,
              switch: (original) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  this.whiteBackground = !original
                })
                return !original
              }
            })
          }
          InnerContainerDivider()
          InnerContainerText({
            text: $r('app.string.blur_effect')
          })
          InnerComponentSet() {
            InnerSwitch({
              title: $r("app.string.blur_background_color"),
              popup: $r('app.string.blur_background_color_tips'),
              initialValue: Pref.blurBackgroundColor,
              switch: (original) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  Pref.blurBackgroundColor = !original
                })
                return !original
              }
            })
            InnerDivider()
            InnerCounter({
              title: $r('app.string.blur_radius'),
              min: 0,
              max: 100,
              resetValue: 80,
              initialValue: Pref.blurRadius,
              gestureAlwaysAnnouncement: true,
              onChange: (value) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  Pref.blurRadius = value
                })
              }
            })
            InnerDivider()
            InnerCounter({
              title: $r('app.string.blur_brightness'),
              min: 0,
              max: 2,
              resetValue: 1.07,
              step: 0.01,
              initialValue: Pref.blurBrightness,
              gestureAlwaysAnnouncement: true,
              onChange: (value) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  Pref.blurBrightness = value
                })
              }
            })
            InnerDivider()
            InnerCounter({
              title: $r('app.string.blur_saturation'),
              min: 0,
              max: 2,
              resetValue: 1.2,
              step: 0.1,
              initialValue: Pref.blurSaturation,
              gestureAlwaysAnnouncement: true,
              onChange: (value) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  Pref.blurSaturation = value
                })
              }
            })
          }
          InnerContainerDivider()
          InnerContainerText({
            text: $r('app.string.controllers')
          })
          InnerComponentSet() {

            InnerCounter({
              title: $r('app.string.inner_cornor_radius'),
              min: 0,
              max: 64,
              resetValue: 16,
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
            InnerDivider()
            InnerCounter({
              title: $r('app.string.outer_cornor_radius'),
              min: 0,
              max: 64,
              resetValue: 32,
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
            InnerDivider()
            InnerSwitch({
              title: $r("app.string.always_fold"),
              popup: $r('app.string.always_fold_tips'),
              initialValue: Pref.alwaysFold,
              switch: (original) => {
                animateTo({
                  duration: 200,
                  curve: curves.springMotion()
                }, () => {
                  Pref.alwaysFold = !original
                })
                return !original
              }
            })
            InnerDivider()
            InnerDraggableContainer({
              title: $r("app.string.control_buttons"),
              areas: [
                {
                  title: $r('app.string.hided'),
                  ordered: false,
                  initialItems: listHidButtons().map(indexToDraggableItem),
                  onEvent: (event) => {
                  }
                },
                {
                  title: $r('app.string.topbar'),
                  max: 4,
                  initialItems: Con.topBar,
                  onEvent: (event) => {
                    Con.topBar = event.items
                  }
                },
                {
                  title: $r('app.string.bottombar'),
                  max: 4,
                  initialItems: Con.bottomBar,
                  onEvent: (event) => {
                    Con.bottomBar = event.items
                  }
                },
                {
                  title: $r('app.string.topbar_folded'),
                  initialItems: Con.topBarFolded,
                  ordered: false,
                  onEvent: (event) => {
                    Con.topBarFolded = event.items
                  }
                },
                {
                  title: $r('app.string.bottombar_folded'),
                  initialItems: Con.bottomBarFolded,
                  ordered: false,
                  onEvent: (event) => {
                    Con.bottomBarFolded = event.items
                  }
                }
              ]
            })
          }
        }
      }
      .width("100%")
      .layoutWeight(1)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r("app.color.rohy_background"))
    .width("100%")
    .layoutWeight(1)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

}

@ComponentV2
export struct FakePlayerPreview {

  @Consumer("useDisplayTestImage")
  private useDisplayTestImage: boolean = false
  @Consumer("whiteBackground")
  private whiteBackground: boolean = false

  private fakeButtonSize: number = 24
  private fakeButtonMargin: number = 12

  private chapters(): ChapterInfo[] {
    return [
      {
        title: "chapter 1",
        start: 0,
        end: 20
      },
      {
        title: $r("app.string.untitled"),
        start: 20,
        end: 45,
      },
      {
        title: $r("app.string.untitled"),
        start: 45,
        end: 80,
      },
      {
        title: $r("app.string.untitled"),
        start: 80,
        end: 100
      }
    ]
  }

  build() {
    Column() {
      Stack() {
        if (this.useDisplayTestImage) {
          Image($r('app.media.display_test'))
            .objectFit(ImageFit.Cover)
            .width("100%")
            .height("100%")
        }

        Column() {
          Row() {
            Column() {
              Row() {
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                  .height(this.fakeButtonSize)
                  .margin({
                    left: this.fakeButtonMargin,
                    top: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                .backgroundColor($r("sys.color.comp_background_tertiary"))
                Text($r("app.string.appearance"))
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .maxLines(1)
                  .textOverflow({
                    overflow: TextOverflow.MARQUEE
                  })
                  .margin({
                    left: this.fakeButtonMargin,
                    right: this.fakeButtonMargin
                  })
                  .layoutWeight(3)
                  .fontColor($r("sys.color.font_primary"))
                Blank()
                  .layoutWeight(1)
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    right: this.fakeButtonMargin,
                    top: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    right: this.fakeButtonMargin,
                    top: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    right: this.fakeButtonMargin,
                    top: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    right: this.fakeButtonMargin,
                    top: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
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
                top: 4,
                left: 4,
                right: 4
              } : 0
            )
            .layoutWeight(1)
            .attributeModifier(Modifiers.backgroundBlur())
          }
          .width("100%")

          Blank()
            .layoutWeight(1)

          Row() {
            Column() {
              Row() {
                Text(`**:**`)
                  .fontSize(12)
                  .margin({
                    left: 16,
                    right: this.fakeButtonMargin
                  })
                  .fontColor($r("sys.color.font_secondary"))
                Stack() {
                  Slider({
                    min: 0,
                    max: 100,
                    step: 1,
                    value: 12
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
                            .fontSize(6)
                            .width(8)
                            .height(8)
                          Blank()
                            .layoutWeight(chapter.end - chapter.start)
                          SymbolGlyph($r('sys.symbol.bookmark_fill'))
                            .fontColor([$r('sys.color.icon_primary')])
                            .fontSize(6)
                            .width(8)
                            .height(8)
                            .visibility(Visibility.Hidden)
                          Blank()
                            .layoutWeight(100 - chapter.end)
                        }
                        .width("100%")
                      })
                    }
                    .width("100%")
                  }
                  .width("100%")

                  Slider({
                    min: 0,
                    max: 100,
                    step: 1,
                    value: 12
                  })
                    .enabled(false)
                    .trackColor(Color.Transparent)
                    .selectedColor(Color.Transparent)
                    .stepColor(Color.Transparent)
                    .width("100%")
                }
                .layoutWeight(1)

                Text(`**:**`)
                  .fontSize(12)
                  .margin({
                    left: this.fakeButtonMargin,
                    right: 16
                  })
                  .fontColor($r("sys.color.font_secondary"))
              }
              .width("100%")

              Row() {
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    left: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    left: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    left: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Blank()
                  .layoutWeight(1)
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    right: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    right: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    right: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
                Button({ type: ButtonType.Circle })
                  .align(Alignment.Center)
                  .width(this.fakeButtonSize)
                .height(this.fakeButtonSize)
                  .margin({
                    right: this.fakeButtonMargin,
                    bottom: this.fakeButtonMargin
                  })
                  .backgroundColor($r("sys.color.comp_background_tertiary"))
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
                bottom: 4,
                left: 4,
                right: 4
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
    .clip(true)
    .backgroundColor(this.whiteBackground ? Color.White : Color.Black)
    .aspectRatio(Sys.isTablet() ? 16 / 9 : 4 / 3)
    .borderRadius(16)
    .width("90%")
    .margin({
      bottom: 8
    })
  }

}
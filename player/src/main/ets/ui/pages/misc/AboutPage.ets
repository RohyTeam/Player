import BuildProfile from 'BuildProfile'
import { getIcon } from '../../../utils/ResourceUtils'
import { InnerButton } from '../../component/inner/InnerButton'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerRow } from '../../component/inner/InnerRow'
import { InnerDivider } from '../../component/inner/InnerDivider'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { InnerContainerText } from '../../component/inner/InnerContainerText'
import { shareUrl } from '../../../utils/MiscUtils'
import { openEmail } from '../../../utils/AbilityUtils'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { BottomAvoidArea } from '../../avoidarea/BottomAvoidArea'

@ComponentV2
export struct AboutPage {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Image(getIcon($r("app.media.rohyplayer_icon")))
              .width("72vp")
              .height("72vp")
              .margin({
                bottom: 8
              })
              .border({
                width: 1,
                radius: 20,
                color: $r("sys.color.icon_fourth")
              })
            Text($r("app.string.PlayerAbility_label"))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
            Blank()
              .height(32)
            Column() {
              InnerComponentSet() {
                InnerRow({
                  title: $r("app.string.version_info"),
                  subtitle: BuildProfile.VERSION_NAME,
                  larger: true
                })
                InnerDivider()
                InnerButton({
                  title: $r("app.string.feedback_email"),
                  subtitle: "botrg@outlook.com",
                  larger: true,
                  clickCallback: () => {
                    openEmail(this.getUIContext(), "botrg@outlook.com", "Rohy 播放器问题反馈")
                  }
                })
                /*InnerDivider()
                InnerButton({
                  title: $r("app.string.source_code"),
                  subtitle: "https://www.github.com/RohyTeam/Player",
                  larger: true,
                  clickCallback: () => {
                    openUrl(this.getUIContext(), "https://www.github.com/RohyTeam/Player")
                  }
                })*/
              }

              InnerContainerDivider()
              InnerContainerText({
                text: $r("app.string.open_source_projects_used")
              })
              InnerComponentSet() {
                InnerButton({
                  title: "FFmpeg",
                  subtitle: "LGPL-2.1, GPL-2.0, GPL-3.0, LGPL-3.0",
                  larger: true,
                  clickCallback: () => {
                    shareUrl(this.getUIContext(), "https://www.ffmpeg.org")
                  }
                })
                InnerDivider()
                InnerButton({
                  title: "openharmony-sig/ohos_ijkplayer",
                  subtitle: "LGPL-2.1",
                  larger: true,
                  clickCallback: () => {
                    shareUrl(this.getUIContext(), "https://gitcode.com/openharmony-sig/ohos_ijkplayer")
                  }
                })
                InnerDivider()
                InnerButton({
                  title: "NaturalIntelligence/fast-xml-parser",
                  subtitle: "MIT",
                  larger: true,
                  clickCallback: () => {
                    shareUrl(this.getUIContext(), "https://github.com/NaturalIntelligence/fast-xml-parser")
                  }
                })
                InnerDivider()
                InnerButton({
                  title: "tongyuyan/harmony-utils",
                  subtitle: "Apache-2.0",
                  larger: true,
                  clickCallback: () => {
                    shareUrl(this.getUIContext(), "https://gitee.com/tongyuyan/harmony-utils")
                  }
                })
                InnerDivider()
                InnerButton({
                  title: "iAmSomeone2/PgsPlusPlus",
                  subtitle: "LGPL-2.1",
                  larger: true,
                  clickCallback: () => {
                    shareUrl(this.getUIContext(), "https://github.com/iAmSomeone2/PgsPlusPlus")
                  }
                })
                InnerDivider()
                InnerButton({
                  title: "weizhenye/ass-compiler",
                  subtitle: "MIT",
                  larger: true,
                  clickCallback: () => {
                    shareUrl(this.getUIContext(), "https://github.com/weizhenye/ass-compiler")
                  }
                })
              }
              InnerContainerDivider()
              Column() {
                Text($r("app.string.icons_introduction"))
                  .fontWeight(FontWeight.Bolder)
                Row() {
                  Image($r("app.media.vivid_gold"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_vivid_audio"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
                Row() {
                  Image($r("app.media.vivid_colorful"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_vivid_hdr"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
                Row() {
                  Image($r("app.media.dolby_colorful"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_dolby"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
                Row() {
                  Image($r("app.media.hdr10_plus_colorful"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_hdr10_plus"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
                Row() {
                  Image($r("app.media.hdr_gold"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_hdr"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
              }
              .alignItems(HorizontalAlign.Start)
              .width("90%")
              InnerContainerDivider()
              Column() {

                Row() {
                  Image($r("app.media.vivid_gray"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_vivid_none"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
                Row() {
                  Image($r("app.media.dolby_gray"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_dolby_none"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
                Row() {
                  Image($r("app.media.hdr10_plus_gray"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_hdr10_plus_none"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
                Row() {
                  Image($r("app.media.hdr_gray"))
                    .borderRadius(4)
                    .height(20)
                    .aspectRatio(2 / 1)
                  Blank()
                    .width(4)
                  Text($r("app.string.icon_hdr_none"))
                }
                .alignItems(VerticalAlign.Center)
                .width("100%")
                .margin({
                  bottom: 8
                })
              }
              .alignItems(HorizontalAlign.Start)
              .width("90%")
            }
            .width("100%")
            .backgroundColor(Color.Transparent)

            BottomAvoidArea()
          }
          .width("100%")
          .layoutWeight(1)
        }
        .width("100%")
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      }
      .width("100%")
      .layoutWeight(1)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .backgroundColor($r("app.color.rohy_background"))
    .hideTitleBar(false)
    .hideToolBar(true)
    .hideBackButton(false)
    .title($r("app.string.about"))
    .width("100%")
    .height("100%")
  }
}
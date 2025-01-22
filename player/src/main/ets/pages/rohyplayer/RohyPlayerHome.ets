import { BreakpointConstants } from '../../common/constants/BreakpointConstants';
import { deviceInfo } from '@kit.BasicServicesKit';
import { CommonConstants } from '../../common/constants/CommonConstants';
import { VideoLibraryPage } from './videolibrary/VideoLibraryPage';
import { AudioLibraryPage } from './audiolibrary/AudioLibraryPage';
import { PlaylistPage } from './playlist/PlaylistPage';
import { MorePage } from './more/MorePage';

export class FooterTab {
  private name: Resource;
  private icon: Resource;

  constructor(name: Resource, icon: Resource) {
    this.name = name;
    this.icon = icon;
  }

  getName(): Resource {
    return this.name;
  }

  getIcon(): Resource {
    return this.icon;
  }

}

@Component
export struct RohyPlayerHome {

  @State
  currentBottomIndex: number = 0;
  @StorageLink('currentWidthBreakpoint')
  currentWidthBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;

  private tabs: FooterTab[] = [
    new FooterTab(
      $r('app.string.home_tab_video'),
      $r('sys.symbol.media_center')
    ),
    new FooterTab(
      $r('app.string.home_tab_audio'),
      $r('sys.symbol.music')
    ),
    new FooterTab(
      $r('app.string.home_tab_playlist'),
      $r('sys.symbol.music_note_list')
    ),
    new FooterTab(
      $r('app.string.home_tab_more'),
      $r('sys.symbol.more')
    )
  ]

  @Builder
  BottomTabBuilder(item: FooterTab, index: number) {
    Column() {
      SymbolGlyph(item.getIcon())
        .fontSize("24fp")
        .fontColor([index == this.currentBottomIndex ? $r("app.color.brand") : $r("app.color.font_tertiary")])
      Text(item.getName())
        .fontSize($r('app.float.tab_font_size'))
        .fontWeight(CommonConstants.FONT_WEIGHT_500)
        .fontColor(index == this.currentBottomIndex ? $r("app.color.brand") : $r("app.color.font_tertiary"))
        .margin({ top: $r('app.float.tab_top_margin') })
        .opacity(index == this.currentBottomIndex ? CommonConstants.TEXT_OPACITY[3] : CommonConstants.TEXT_OPACITY[0])
    }
    .padding({
      bottom: this.currentWidthBreakpoint !== BreakpointConstants.BREAKPOINT_LG && deviceInfo.deviceType !==
    CommonConstants.DEVICE_TYPES[0] ? $r('app.float.bottom_navigation') : 0,
      top: this.currentWidthBreakpoint !== BreakpointConstants.BREAKPOINT_LG && deviceInfo.deviceType !==
    CommonConstants.DEVICE_TYPES[0] ? $r('app.float.top_navigation') : 0,
    }
    )
    .height(
      this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG ? $r('app.float.tab_height_lg') :
      CommonConstants.FULL_PERCENT
    )
    .width(CommonConstants.FULL_PERCENT)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    RelativeContainer() {
      Tabs({
        barPosition: this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG ? BarPosition.Start :
        BarPosition.End
      }) {
        TabContent() {
          VideoLibraryPage()
        }
        .tabBar(this.BottomTabBuilder(this.tabs[0], 0))

        /*
        TabContent() {
          AudioLibraryPage()
        }
        .tabBar(this.BottomTabBuilder(this.tabs[1], 1))
        TabContent() {
          PlaylistPage()
        }
        .tabBar(this.BottomTabBuilder(this.tabs[2], 2))
        */
        TabContent() {
          MorePage()
        }
        .tabBar(this.BottomTabBuilder(this.tabs[3], 1))
      }
      .scrollable(false)
      .onChange((index) => {
        this.currentBottomIndex = index
      })
      .barWidth(
        this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG ?
        $r('app.float.bottom_tab_bar_width_lg') :
        CommonConstants.FULL_PERCENT
      )
      .barHeight(
        this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG
          ? CommonConstants.FULL_PERCENT : ((deviceInfo.deviceType === CommonConstants.DEVICE_TYPES[0]
          ? $r('app.float.tab_size_lg') : $r('app.float.tab_size')))
      )
      .barMode(
        this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG ? BarMode.Scrollable : BarMode.Fixed,
        {
          nonScrollableLayoutStyle: LayoutStyle.ALWAYS_CENTER
        }
      )
      .vertical(this.currentWidthBreakpoint === BreakpointConstants.BREAKPOINT_LG)
      .backgroundColor($r("app.color.comp_background_focus"))
      .height("100%")
      .width("100%")
    }
    .height("100%")
    .width("100%")
    .backgroundColor($r("app.color.comp_background_focus"))
  }
}
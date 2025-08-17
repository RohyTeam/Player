import { PlaylistDao } from "../../../database/dao/PlaylistDao";
import { DataSources } from "../../../datasource/DataSources";
import { Modifiers } from "../../attributemodifier/Modifiers";
import { curves } from "@kit.ArkUI";
import { SimpleLoadingPage } from "../../component/page/SimpleLoadingPage";

@ComponentV2
export struct GeneralPlaylistView {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    DataSources.PLAYLIST.reloadInitially()
  }

  build() {
    if (DataSources.PLAYLIST.alreadyReloaded) {
      Grid(undefined, { regularSize: [1, 1] }) {
        LazyForEach(DataSources.PLAYLIST, (playlist: PlaylistDao) => {
          GridItem() {
            Button() {
              Column() {
                Image($r("app.media.hidisk_icon_folder"))
                  .aspectRatio(4 / 3)
                  .width("100%")
                  .margin({
                    top: 8,
                    left: 8,
                    right: 8,
                    bottom: 4
                  })
                Text(playlist.name)
                  .margin({
                    bottom: 8,
                    left: 8,
                    right: 8
                  })
              }
            }
            .onClick(() => {
              let params: Record<string, object> = {
                'dao': playlist,
                'path': []
              }
              this.indexNavigator.pushPath({ name: `PlaylistView`, param: params })
            })
            .borderRadius(16)
            .type(ButtonType.Normal)
            .backgroundColor(Color.Transparent)
          }
          .transition(
            TransitionEffect.OPACITY
              .combine(
                TransitionEffect.scale({
                  x: 0.7,
                  y: 0.7
                })
              )
              .animation({
                duration: 200,
                curve: curves.springMotion()
              })
          )
        })
      }
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .attributeModifier(Modifiers.gridLayout(this.getUIContext()))
      .padding({
        left: "5%",
        right: "5%",
      })
      .rowsGap(8)
      .columnsGap(8)
      .layoutDirection(GridDirection.Row)
      .width("100%")
      .height("100%")
    } else {
      SimpleLoadingPage()
    }
  }

}
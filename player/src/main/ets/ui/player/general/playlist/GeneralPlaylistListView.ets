import { PlaylistDao } from '../../../../database/dao/PlaylistDao';
import { DataSources } from '../../../../datasource/DataSources';
import { Modifiers } from '../../../attributemodifier/Modifiers';
import { curves } from '@kit.ArkUI';
import { SimpleLoadingPage } from '../../../component/page/SimpleLoadingPage';
import { PlaylistItem } from './PlaylistItem';

@ComponentV2
export struct GeneralPlaylistView {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()
  @Consumer('hideSearch')
  hideSearch: boolean = false

  build() {
    if (DataSources.PLAYLIST.alreadyReloaded) {
      Grid(undefined, { regularSize: [1, 1] }) {
        LazyForEach(DataSources.PLAYLIST, (playlist: PlaylistDao) => {
          GridItem() {
            PlaylistItem({
              playlist: playlist
            })
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
      .onScrollFrameBegin((offset, state) => {
        animateTo({
          duration: 200,
          curve: curves.springMotion()
        }, () => {
          if (offset > 0) {
            this.hideSearch = true
          } else if (offset < 0) {
            this.hideSearch = false
          }
        })
        return {
          offsetRemain: offset
        }
      })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .attributeModifier(Modifiers.gridLayout(this.getUIContext()))
      .padding({
        left: 16,
        right: 16,
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
import { SavedVideoMetadata } from "../../../../metadata/SavedVideoMetadata"
import { VideoMetadataManager } from "../../../../metadata/VideoMetadataManager"
import { PlayerContext } from "../../../../player/PlayerContext"
import { LocalFileVideoSource } from "../../../../player/VideoSource"
import { PlaylistVideo } from "../../../../playlist/PlaylistStructure"
import { SimpleLoadingPage } from "../../../component/page/SimpleLoadingPage"
import { fileShare } from "@kit.CoreFileKit"
import { image } from "@kit.ImageKit"
import { Modifiers } from "../../../attributemodifier/Modifiers"
import { convertNumberToDurationString } from "../../../../utils/NumberUtils"

@ComponentV2
export struct PlaylistVideoItem {

  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  @Param
  @Require
  video: PlaylistVideo

  @Local
  metadata?: SavedVideoMetadata

  @Local
  playerContext: PlayerContext = PlayerContext.reach(this.getUIContext())

  build() {
    if (this.metadata) {
      Button() {
        Column() {
          Stack() {
            Image(this.metadata.metadata.cover as string)
              .objectFit(ImageFit.Fill)
              .height("100%")
              .width("100%")
            Column() {
              Blank()
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
              Row() {
                Blank()
                  .backgroundColor(Color.Transparent)
                  .layoutWeight(1)
                Column() {
                  Text(convertNumberToDurationString(this.metadata.metadata.duration))
                }
                .borderRadius(6)
                .padding(2)
                .margin(2)
                .attributeModifier(Modifiers.backgroundBlur())
              }
              .backgroundColor(Color.Transparent)
            }
            .backgroundColor(Color.Transparent)
            .height("100%")
            .width("100%")
          }
          .clip(true)
          .aspectRatio(4 / 3)
          .width("100%")
          .margin({
            top: 8,
            left: 8,
            right: 8,
            bottom: 4
          })
          .borderRadius(8)
          Text(this.video.name)
            .margin({
              bottom: 8,
              left: 8,
              right: 8
            })
        }
      }
      .onClick(() => {
        fileShare.activatePermission([{
          uri: this.video.url,
          operationMode: fileShare.OperationMode.READ_MODE
        }])
          .then(() => {
            this.playerContext.video = true
            this.playerContext.videoSource = new LocalFileVideoSource(
              true,
              this.metadata!,
              this.video.url,
              this.video.name
            )
            this.indexNavigator.pushPath({ name: "Player" })
          })
      })
      .borderRadius(16)
      .type(ButtonType.Normal)
      .backgroundColor(Color.Transparent)
    } else {
      Column() {
        SimpleLoadingPage()
      }
      .onAppear(() => {
        VideoMetadataManager.loadAsync(this.video.identity)
          .then((savedMetadata) => {
            this.metadata = savedMetadata
          })
      })
      .aspectRatio(4 / 3)
      .width("100%")
      .margin({
        top: 8,
        left: 8,
        right: 8,
        bottom: 4
      })
    }
  }

}
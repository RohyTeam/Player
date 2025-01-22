import { AVVideoPlayer } from "./AVVideoPlayer"


@Component
export struct NativePlayerPage {

  @BuilderParam
  title: string

  @BuilderParam
  url: string

  build() {
    Stack() {
      AVVideoPlayer({
        title: this.title,
        url: this.url
      })
      /*
      Video({
        src: this.url
      })
        .width("100%")
        .height("100%")*/
    }
    .width("100%")
    .height("100%")
  }

}
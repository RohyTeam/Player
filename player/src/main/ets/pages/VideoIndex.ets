import { Want } from '@kit.AbilityKit';
import { NativePlayerPage } from './player/NativePlayerPage';

class EventData {
  launchWant: Want | undefined = undefined
}

@Entry
@Component
struct VideoIndex {

  @State
  private title: string = ''

  @State
  private url: string | undefined = undefined

  aboutToAppear(): void {
    console.error("trying to play video")
    let eventData = new EventData()
    getContext(this).eventHub.emit('getAbilityData', eventData)
    this.url = eventData.launchWant!.parameters!.url as string
    console.error(`received url is: ${this.url}`)
    this.title = eventData.launchWant!.parameters!.title as string
  }

  build() {
    Stack() {
      NativePlayerPage({
        title: this.title,
        url: this.url
      })
    }
    .width("100%")
    .height("100%")
  }

}
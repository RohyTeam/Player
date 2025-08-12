import { Win, WindowContext } from '../../context/WindowContext'
import { window } from '@kit.ArkUI'

@ComponentV2
export struct BottomAvoidArea {
  @Local
  private win: WindowContext = Win.get(this.getUIContext())

  build() {
    if (this.win.windowStatusType != window.WindowStatusType.FLOATING) {
      Blank()
        .height(28)
    }
  }
}
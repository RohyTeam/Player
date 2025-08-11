import { Win, WindowContext } from '../../context/WindowContext'

@ComponentV2
export struct BottomAvoidArea {
  @Local
  private win: WindowContext = Win.get(this.getUIContext())

  build() {
    Blank()
      .height(28)
  }
}
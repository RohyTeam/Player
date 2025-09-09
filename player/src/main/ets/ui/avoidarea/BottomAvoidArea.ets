import { WindowContext } from '../../context/WindowContext'

@ComponentV2
export struct BottomAvoidArea {

  @Param
  static: boolean = true

  @Local
  private win: WindowContext = WindowContext.reach(this.getUIContext())

  build() {
    Blank()
      .height(this.static ? this.win.staticBottomAvoid : this.win.bottomAvoid)
  }
}
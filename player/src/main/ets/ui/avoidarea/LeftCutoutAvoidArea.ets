import { WindowContext } from '../../context/WindowContext'

@ComponentV2
export struct LeftCutoutAvoidArea {

  @Param
  extra: number = 0

  @Local
  private win: WindowContext = WindowContext.reach(this.getUIContext())

  build() {
    Blank()
      .width(this.win.leftCutoutAvoid + (this.win.leftCutoutAvoid > 0 ? 16 : 0) + this.extra)
  }

}
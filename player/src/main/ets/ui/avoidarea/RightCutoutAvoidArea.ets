import { WindowContext } from '../../context/WindowContext'

@ComponentV2
export struct RightCutoutAvoidArea {

  @Param
  extra: number = 0

  @Local
  private win: WindowContext = WindowContext.reach(this.getUIContext())

  build() {
    Blank()
      .width(this.win.rightCutoutAvoid + (this.win.rightCutoutAvoid > 0 ? 16 : 0) + this.extra)
  }

}
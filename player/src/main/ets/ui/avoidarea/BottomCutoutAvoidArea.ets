import { WindowContext } from '../../context/WindowContext'

@ComponentV2
export struct BottomCutoutAvoidArea {

  @Param
  extra: number = 0

  @Local
  private win: WindowContext = WindowContext.reach(this.getUIContext())

  build() {
    Blank()
      .height(this.win.bottomCutoutAvoid + this.extra)
  }

}
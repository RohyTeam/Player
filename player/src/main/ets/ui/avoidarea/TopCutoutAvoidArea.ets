import { WindowContext } from '../../context/WindowContext'

@ComponentV2
export struct TopCutoutAvoidArea {

  @Param
  extra: number = 0

  @Local
  private win: WindowContext = WindowContext.reach(this.getUIContext())

  build() {
    Blank()
      .height(this.win.topCutoutAvoid + this.extra)
  }

}
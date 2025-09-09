import { WindowContext } from '../../context/WindowContext'

@ComponentV2
export struct TopAvoidArea {

  @Param
  static: boolean = true

  @Local
  private win: WindowContext = WindowContext.reach(this.getUIContext())

  build() {
    Blank()
      .height(this.static ? this.win.staticTopAvoid : this.win.topAvoid)
  }

}
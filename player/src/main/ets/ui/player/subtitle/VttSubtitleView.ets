import { Cue } from "../../../lib/subtitle/vtt/VttParser"
import { PlayerContext } from "../../../player/PlayerContext"
import { LengthMetricsUnit } from "@kit.ArkUI"


@ComponentV2
export struct VttSubtitleView {

  build() {

  }

}

@ComponentV2
struct VttSubtitle {

  @Param
  @Require
  cue: Cue
  @Param
  @Require
  playerContext: PlayerContext
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  @Local
  private canvasWidth: number = 1
  @Local
  private canvasHeight: number = 1

  build() {
    Column() {

    }

  }

}
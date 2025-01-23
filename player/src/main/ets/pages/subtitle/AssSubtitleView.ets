import { CompiledASS, CompiledASSStyle, Dialogue, DialogueFragment, DialogueSlice } from "../../lib/ass_compiler"
import { abgrColorStr2argbColor } from "../../util/StringUtil"
import { LengthMetricsUnit } from "@kit.ArkUI"

@Component
export struct AssSubtitleView {

  @Prop
  subtitle: CompiledASS
  @Prop
  actualWidth: number
  @Prop
  actualHeight: number
  @Link
  currentTime: number

  @State
  dialogueStyles: Record<string, CompiledASSStyle> = {}

  @StorageLink("screenWidthVp")
  private screenWidthVp: number = this.actualWidth
  @StorageLink("screenHeightVp")
  private screenHeightVp: number = this.actualHeight

  aboutToAppear() {
    this.dialogueStyles = this.subtitle.styles
  }

  build() {
    Stack() {
      ForEach(this.subtitle.dialogues, (dialogue: Dialogue) => {
        if (dialogue.start * 1000 <= this.currentTime && dialogue.end * 1000 >= this.currentTime) {
          ForEach(dialogue.slices, (slice: DialogueSlice) => {
            ForEach(slice.fragments, (fragment: DialogueFragment) => {
              Column() {
                AdvancedSubtitleV2({
                  assFile: this.subtitle,
                  surfaceWidth: this.actualWidth,
                  surfaceHeight: this.actualHeight,
                  pos: dialogue.move != undefined ? {
                    x: dialogue.move.x1 + ((dialogue.move.x2 - dialogue.move.x1) * ((this.currentTime - (dialogue.start * 1000)) / (dialogue.end * 1000 - dialogue.start * 1000))),
                    y: dialogue.move.y1 + ((dialogue.move.y2 - dialogue.move.y1) * ((this.currentTime - (dialogue.start * 1000)) / (dialogue.end * 1000 - dialogue.start * 1000))),
                  } : (
                    dialogue.pos != undefined ? dialogue.pos : undefined
                  ),
                  dialogue: dialogue,
                  slice: slice,
                  style: this.dialogueStyles[slice.style] || this.dialogueStyles[dialogue.style]
                })
                /*
                AdvancedSubtitle({
                  assFile: this.subtitle,
                  surfaceWidth: this.actualWidth,
                  surfaceHeight: this.actualHeight,
                  pos: dialogue.move != undefined ? {
                    x: dialogue.move.x1 + ((dialogue.move.x2 - dialogue.move.x1) * ((this.currentTime - (dialogue.start * 1000)) / (dialogue.end * 1000 - dialogue.start * 1000))),
                    y: dialogue.move.y1 + ((dialogue.move.y2 - dialogue.move.y1) * ((this.currentTime - (dialogue.start * 1000)) / (dialogue.end * 1000 - dialogue.start * 1000))),
                  } : (
                    dialogue.pos != undefined ? dialogue.pos : undefined
                  ),
                  dialogue: dialogue,
                  slice: slice,
                  fragment: fragment,
                  style: this.dialogueStyles[slice.style] || this.dialogueStyles[dialogue.style]
                })*/
              }
              .height("100%")
              .width("100%")
              .zIndex(dialogue.layer)
            })
          })
        }
      })
    }
    .height("100%")
    .width("100%")
  }

  @Builder
  private Subtitle(
    dialogue: Dialogue,
    slice: DialogueSlice,
    fragment: DialogueFragment,
    layer: number
  ) {
    if (this.dialogueStyles[slice.style] != undefined) {
      Stack() {
        Text(fragment.text)
          .fontWeight(FontWeight.Normal)
          .fontColor(`${abgrColorStr2argbColor(this.dialogueStyles[slice.style].style.PrimaryColour.substring(2))}`)
          .zIndex(layer + 1)
          .onAppear(() => {
            console.error(`showing subtitle text: ${fragment.text}, color: ${abgrColorStr2argbColor(this.dialogueStyles[slice.style].style.PrimaryColour.substring(2))}`)
          })
      }
    } else if (this.dialogueStyles[dialogue.style] != undefined) {
      Stack() {
        if (this.dialogueStyles[dialogue.style].style.OutlineColour.length == 10) {
          Text(fragment.text)
            .fontWeight(FontWeight.Bold)
            .fontColor(`${abgrColorStr2argbColor(this.dialogueStyles[dialogue.style].style.OutlineColour.substring(2))}`)
            .zIndex(layer)
        }
        Text(fragment.text)
          .fontColor(`${abgrColorStr2argbColor(this.dialogueStyles[dialogue.style].style.PrimaryColour.substring(2))}`)
          .zIndex(layer + 1)
          .onAppear(() => {
            console.error(`showing subtitle text: ${fragment.text}, color: ${abgrColorStr2argbColor(this.dialogueStyles[slice.style].style.PrimaryColour.substring(2))}`)
          })
      }
    } else {
      Text(fragment.text)
        .onAppear(() => {
          console.error(`showing subtitle text: ${fragment.text}`)
        })
    }
  }

  private alignment(num: number): Alignment {
    switch (num) {
      case 1:
        return Alignment.BottomStart
      case 2:
        return Alignment.Bottom
      case 3:
        return Alignment.BottomEnd
      case 4:
        return Alignment.TopStart
      case 5:
        return Alignment.Top
      case 6:
        return Alignment.TopEnd
      case 7:
        return Alignment.Start
      case 8:
        return Alignment.Center
      case 9:
        return Alignment.End
      default:
        return Alignment.Bottom
    }
  }

}

interface Position {
  x: number
  y: number
}

@Component
struct AdvancedSubtitle {

  @Prop
  @Require
  surfaceWidth: number
  @Prop
  @Require
  surfaceHeight: number

  @Prop
  @Require
  @Watch("onPosUpdate")
  pos: Position | undefined

  @Prop
  @Require
  assFile: CompiledASS
  @Prop
  @Require
  dialogue: Dialogue
  @Prop
  @Require
  slice: DialogueSlice
  @Prop
  @Require
  fragment: DialogueFragment
  @Prop
  @Require
  style: CompiledASSStyle | undefined

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  onPosUpdate(propName: string): void {
    this.redraw()
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.redraw()
      })
  }

  private redraw() {
    this.context.reset()
    this.context.font = `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" : "normal"} ${this.style?.style.Fontsize || 60}px`
    let textMetrics = this.context.measureText(this.fragment.text)

    let textWidth = textMetrics.width
    let textHeight = textMetrics.height

    let x: number
    let y: number
    if (this.pos != undefined) {
      x = (this.pos.x / this.assFile.width) * this.surfaceWidth
      y = ((this.pos.y / this.assFile.height) * this.surfaceHeight) + textHeight
    } else {
      if (this.dialogue.alignment == 1) {
        x = 0
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 2) {
        x = (this.surfaceWidth - textWidth) / 2
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 3) {
        x = this.surfaceWidth - textWidth
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 4) {
        x = 0
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - textHeight) / 2)
      } else if (this.dialogue.alignment == 5) {
        x = (this.surfaceWidth - textWidth) / 2
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - textHeight) / 2)
      } else if (this.dialogue.alignment == 6) {
        x = this.surfaceWidth - textWidth
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - textHeight) / 2)
      } else if (this.dialogue.alignment == 7) {
        x = 0
        y = textHeight
      } else if (this.dialogue.alignment == 8) {
        x = (this.surfaceWidth - textWidth) / 2
        y = textHeight
      } else if (this.dialogue.alignment == 9) {
        x = this.surfaceWidth - textWidth
        y = textHeight
      } else {
        x = 0
        y = 0
      }
    }
    if (this.dialogue.alignment == 1 || this.dialogue.alignment == 4 || this.dialogue.alignment == 7) {
      x += this.dialogue.margin.left
    }
    if (this.dialogue.alignment == 3 || this.dialogue.alignment == 6 || this.dialogue.alignment == 9) {
      x -= this.dialogue.margin.right
    }
    if (this.dialogue.alignment >= 1 && this.dialogue.alignment <= 3) {
      y -= this.dialogue.margin.vertical
    } else if (this.dialogue.alignment >= 7 && this.dialogue.alignment <= 0) {
      y += this.dialogue.margin.vertical
    }

    console.error(`displaying subtitle content (${this.fragment.text}) at ${x}, ${y}, height: ${textHeight} with color ${abgrColorStr2argbColor(this.style?.style.PrimaryColour.substring(2) || "00ffffff")}`)

    this.context.shadowColor = abgrColorStr2argbColor(this.style?.style.BackColour.substring(2) || "00ffffff")

    if (this.style?.style.BorderStyle == 1 && this.style?.style.OutlineColour.length == 10) {
      this.context.lineWidth = this.style.style.Outline + 4
      this.context.strokeStyle = abgrColorStr2argbColor(this.style?.style.OutlineColour.substring(2) || "00ffffff")
      this.context.strokeText(this.fragment.text, x, y)
    }
    this.context.lineWidth = 1
    this.context.fillStyle = abgrColorStr2argbColor(this.style?.style.PrimaryColour.substring(2) || "00ffffff")
    this.context.fillText(this.fragment.text, x, y)
  }

}

@Component
struct AdvancedSubtitleV2 {

  @Prop
  @Require
  surfaceWidth: number
  @Prop
  @Require
  surfaceHeight: number

  @Prop
  @Require
  @Watch("onPosUpdate")
  pos: Position | undefined

  @Prop
  @Require
  assFile: CompiledASS
  @Prop
  @Require
  dialogue: Dialogue
  @Prop
  @Require
  slice: DialogueSlice
  @Prop
  @Require
  style: CompiledASSStyle | undefined

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  onPosUpdate(propName: string): void {
    this.redraw()
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.redraw()
      })
  }

  private redraw() {
    this.context.reset()
    let baseStyle = `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" : "normal"} ${this.style?.style.Fontsize || 60}px`
    let totalWidth = 0
    let totalHeight = 0
    for (let fragment of this.slice.fragments) {
      this.context.font = baseStyle
      if (fragment.tag.fs != undefined) {
        this.context.font = `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" : "normal"} ${fragment.tag.fs}px`
      }
      let textMetrics = this.context.measureText(fragment.text)
      totalWidth += textMetrics.width
      totalHeight += textMetrics.height
    }

    let textWidth = totalWidth
    let textHeight = totalHeight

    let x: number
    let y: number
    if (this.pos != undefined) {
      x = (this.pos.x / this.assFile.width) * this.surfaceWidth
      y = ((this.pos.y / this.assFile.height) * this.surfaceHeight) + textHeight
    } else {
      if (this.dialogue.alignment == 1) {
        x = 0
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 2) {
        x = (this.surfaceWidth - textWidth) / 2
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 3) {
        x = this.surfaceWidth - textWidth
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 4) {
        x = 0
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - textHeight) / 2)
      } else if (this.dialogue.alignment == 5) {
        x = (this.surfaceWidth - textWidth) / 2
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - textHeight) / 2)
      } else if (this.dialogue.alignment == 6) {
        x = this.surfaceWidth - textWidth
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - textHeight) / 2)
      } else if (this.dialogue.alignment == 7) {
        x = 0
        y = textHeight
      } else if (this.dialogue.alignment == 8) {
        x = (this.surfaceWidth - textWidth) / 2
        y = textHeight
      } else if (this.dialogue.alignment == 9) {
        x = this.surfaceWidth - textWidth
        y = textHeight
      } else {
        x = 0
        y = 0
      }
    }
    if (this.dialogue.alignment == 1 || this.dialogue.alignment == 4 || this.dialogue.alignment == 7) {
      x += this.dialogue.margin.left
    }
    if (this.dialogue.alignment == 3 || this.dialogue.alignment == 6 || this.dialogue.alignment == 9) {
      x -= this.dialogue.margin.right
    }
    if (this.dialogue.alignment >= 1 && this.dialogue.alignment <= 3) {
      y -= this.dialogue.margin.vertical
    } else if (this.dialogue.alignment >= 7 && this.dialogue.alignment <= 0) {
      y += this.dialogue.margin.vertical
    }

    this.context.shadowColor = abgrColorStr2argbColor(this.style?.style.BackColour.substring(2) || "00ffffff")

    let previousWidth = 0

    for (let fragment of this.slice.fragments) {
      console.error(`displaying subtitle content (${fragment.text}) at ${x + previousWidth}, ${y} with color ${abgrColorStr2argbColor(this.style?.style.PrimaryColour.substring(2) || "00ffffff")}`)
      this.context.font = baseStyle
      if (fragment.tag.fs) {
        this.context.font = `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" : "normal"} ${fragment.tag.fs}px`
      }
      if (fragment.tag.xbord || 1 > 0 && fragment.tag.ybord || 1 > 0) {
        if (this.style?.style.BorderStyle == 1 && this.style?.style.OutlineColour.length == 10) {
          if (fragment.tag.c3 != undefined) {
            this.context.strokeStyle = `#${fragment.tag.c3}`
          } else {
            this.context.strokeStyle = abgrColorStr2argbColor(this.style?.style.OutlineColour.substring(2) || "00ffffff")
          }
          this.context.lineWidth = this.style.style.Outline + 1
          this.context.strokeText(fragment.text, x + previousWidth, y)
        }
      }
      if (fragment.tag.c1 != undefined) {
        this.context.fillStyle = `#${fragment.tag.c1}`
      } else {
        this.context.fillStyle = abgrColorStr2argbColor(this.style?.style.PrimaryColour.substring(2) || "00ffffff")
      }
      this.context.lineWidth = 1
      this.context.fillText(fragment.text, x + previousWidth, y)
      previousWidth += this.context.measureText(fragment.text).width
    }
  }

}
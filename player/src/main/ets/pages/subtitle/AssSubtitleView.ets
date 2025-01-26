import { CompiledASS, CompiledASSStyle, Dialogue, DialogueFragment, DialogueSlice } from '../../lib/ass_compiler'
import { abgrColorStr2argbColor, bgrColorStr2rgbColor } from '../../util/StringUtil'
import { LengthMetricsUnit, matrix4 } from '@kit.ArkUI'
import { JSON } from '@kit.ArkTS'

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

  aboutToAppear() {
    this.dialogueStyles = this.subtitle.styles
  }

  build() {
    Stack() {
      /**
       * 将字幕中的所有对话循环
       */
      ForEach(this.subtitle.dialogues, (dialogue: Dialogue) => {
        /**
         * 确保当前的对话可见再显示
         */
        if (dialogue.start * 1000 <= this.currentTime && dialogue.end * 1000 >= this.currentTime) {
          Stack() {
            AdvancedSubtitleV3({
              surfaceWidth: this.actualWidth,
              surfaceHeight: this.actualHeight,
              assFile: this.subtitle,
              dialogue: dialogue,
              currentPosition: this.currentTime
            })
          }
          .height("100%")
          .width("100%")
          .zIndex(dialogue.layer)
          /**
           * 将对话中所有的 slice 进行循环，目前还没有看到要让所有 slice 同时渲染的必要，所以为了方便处理先分开渲染
           */
          /*ForEach(dialogue.slices, (slice: DialogueSlice) => {
            *//**
             * 铺平整个画面
             *//*
            Column() {
              *//**
               * 显示字幕
               *//*
              AdvancedSubtitle({
                assFile: this.subtitle,
                surfaceWidth: this.actualWidth,
                surfaceHeight: this.actualHeight,
                pos: dialogue.move != undefined ? {
                  x: dialogue.move.x1 + ((dialogue.move.x2 - dialogue.move.x1) *
                    ((this.currentTime - (dialogue.start * 1000)) / (dialogue.end * 1000 - dialogue.start * 1000))),
                  y: dialogue.move.y1 + ((dialogue.move.y2 - dialogue.move.y1) *
                    ((this.currentTime - (dialogue.start * 1000)) / (dialogue.end * 1000 - dialogue.start * 1000))),
                } : (
                  dialogue.pos != undefined ? dialogue.pos : undefined
                ),
                dialogue: dialogue,
                slice: slice,
                style: this.dialogueStyles[slice.style] || this.dialogueStyles[dialogue.style]
              })
            }
            .height("100%")
            .width("100%")
            .zIndex(dialogue.layer)
          })*/
        }
      })
    }
    .height("100%")
    .width("100%")
  }
}

interface Position {
  x: number
  y: number
}

interface Size {
  width: number
  height: number
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

  /**
   * 绘制字幕
   */
  private redraw() {
    // 清空画布
    this.context.reset()
    // 获取基础字体样式，在没有特殊标签情况下使用
    let baseStyle = `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" :
      "normal"} ${this.style?.style.Fontsize || 60}px`

    // 用于计算字幕大小，以确定左下角的位置
    let totalWidth = 0
    let totalHeight = 0

    // 将所有的 fragment 循环，计算加在一起的总长度，因为 fragment 其实是同一个对话但是对不同位置的文字进行了不同程度的标签覆写导致的碎片文本
    for (let fragment of this.slice.fragments) {
      this.context.font = baseStyle
      // 如果这个碎片文本的标签中有字体大小的修改，实际上这个 fs 改的是行高，但是 Canvas 没法修改，只能修改字体大小
      if (fragment.tag.fs != undefined) {
        this.context.font =
          `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" :
            "normal"} ${fragment.tag.fs}px`
      }
      // 计算在画布上的大小
      let textMetrics = this.context.measureText(fragment.text)
      // 添加到总和中
      totalWidth += textMetrics.width
      // 理论上字幕是单行，文本高度应该由最高的文本高度决定
      totalHeight = textMetrics.height > totalHeight ? textMetrics.height : totalHeight
    }

    let x: number
    let y: number

    // 如果设置了位置参数，那么这个字幕的位置就是绝对位置而不是相对位置
    if (this.pos != undefined) {
      // 因为画布大小和视频实际的分辨率不同，所以通过将坐标除以视频实际大小，再乘画布的大小就可以获得在画布上的相对坐标了，但是有误差，TODO: 需要优化
      x = (this.pos.x / this.assFile.width) * this.surfaceWidth
      y = ((this.pos.y / this.assFile.height) * this.surfaceHeight) + totalHeight
    } else {
      // 没设置位置参数，就通过对齐来进行定位
      if (this.dialogue.alignment == 1) {
        // 1 是左下角
        // x 定位为最左边，所以为 0
        // y 定位为最下面，所以为画布高度
        x = 0
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 2) {
        // 2 是下方向中对齐
        // x 定位为中间，为画布宽度减半，但是文字对齐点是文本左下角，所以横向要减去半个文本宽度才能将文本定位在中间
        // y 参考 1
        x = (this.surfaceWidth - totalWidth) / 2
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 3) {
        // 3 是右下角
        // x 定位为最右边，为画布宽度，但是文字对齐点是文本左下角，所以横向要减去一个文本宽度才能将文本定位在右边
        // y 参考 1
        x = this.surfaceWidth - totalWidth
        y = this.surfaceHeight
      } else if (this.dialogue.alignment == 4) {
        // 4 为中间向左对齐
        // x 参考 1
        // y 定位为中间，为画布高度减半，但文字对齐是左下角，所以竖向要加上半个高度才能将文本定位在中间
        x = 0
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - totalHeight) / 2)
      } else if (this.dialogue.alignment == 5) {
        // 5 为画布最中间
        // x 参考 2
        // y 参考 4
        x = (this.surfaceWidth - totalWidth) / 2
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - totalHeight) / 2)
      } else if (this.dialogue.alignment == 6) {
        // 6 为中间向右对齐
        // x 参考 3
        // y 参考 4
        x = this.surfaceWidth - totalWidth
        y = (this.surfaceHeight / 2) + ((this.surfaceHeight - totalHeight) / 2)
      } else if (this.dialogue.alignment == 7) {
        // 7 为左上角
        // x 参考 1
        // y 定位为最顶部，为 0，但因为文字有高度，所以竖向上要加一个文本高度
        x = 0
        y = totalHeight
      } else if (this.dialogue.alignment == 8) {
        // 8 为画布上方相中对齐
        // x 参考 2
        // y 参考 7
        x = (this.surfaceWidth - totalWidth) / 2
        y = totalHeight
      } else if (this.dialogue.alignment == 9) {
        // 9 为右上角
        // x 参考 3
        // y 参考 7
        x = this.surfaceWidth - totalWidth
        y = totalHeight
      } else {
        // 理论上不会出现这个情况
        x = 0
        y = 0
      }
    }
    // 对于 margin，我采用了比较不太寻常的处理方案，只有一个方向贴边的时候，才会处理那个方向的 margin
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

    // 投影颜色
    this.context.shadowColor = abgrColorStr2argbColor(this.style?.style.BackColour.substring(2) || "00ffffff")

    // 已经渲染的文本的总长度，防止文字重叠
    let previousWidth = 0

    // 遍历每一个文本碎片，开始渲染
    for (let fragment of this.slice.fragments) {
      console.error(`displaying subtitle content (${fragment.text}) at ${x +
        previousWidth}, ${y} with color ${abgrColorStr2argbColor(this.style?.style.PrimaryColour.substring(2) ||
        "00ffffff")}`)
      this.context.font = baseStyle
      // 如果文本碎片的标签修改了文字大小，修改上下文的字体
      if (fragment.tag.fs) {
        this.context.font =
          `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" :
            "normal"} ${fragment.tag.fs}px`
      }
      // 确保边框是否应该显示
      if (fragment.tag.xbord || 1 > 0 && fragment.tag.ybord || 1 > 0) {
        if (this.style?.style.BorderStyle == 1 && this.style?.style.OutlineColour.length == 10) {
          // 如果文本碎片的标签修改了描边的颜色
          if (fragment.tag.c3 != undefined) {
            this.context.strokeStyle = `#${fragment.tag.c3}`
          } else {
            this.context.strokeStyle =
              abgrColorStr2argbColor(this.style?.style.OutlineColour.substring(2) || "00ffffff")
          }
          this.context.lineWidth = this.style.style.Outline + 1
          this.context.strokeText(fragment.text, x + previousWidth, y)
        }
      }
      // 如果文本碎片的标签修改了文本的颜色
      if (fragment.tag.c1 != undefined) {
        this.context.fillStyle = `#${fragment.tag.c1}`
      } else {
        this.context.fillStyle = abgrColorStr2argbColor(this.style?.style.PrimaryColour.substring(2) || "00ffffff")
      }
      this.context.lineWidth = 1
      this.context.fillText(fragment.text, x + previousWidth, y)
      // 增长已渲染文本的总长度，防止文字重叠
      previousWidth += this.context.measureText(fragment.text).width
    }
  }
}

interface SubtitleV3Fragment {

  text: string
  font: SubtitleFontStyle
  color: string
  outline?: SubtitleOutline
  decoration: SubtitleDecoration
  size: Size
  matrix: matrix4.Matrix4Transit
  position: Position
  rotation: SubtitleRotation
  movement?: SubtitleMovement

}

@Observed
class SubtitleFragments extends Array<SubtitleV3Fragment> {
}

interface SubtitleMovement {

  start: number
  end: number
  fromX: number
  fromY: number
  toX: number
  toY: number

}

interface SubtitleRotation {

  x: Rotation,
  y: Rotation,
  z: Rotation

}

interface Rotation {

  centerX: number
  centerY: number
  angle: number

}

interface SubtitleDecoration {

  underlined: boolean
  strikethrough: boolean

}

interface SubtitleOutline {

  thickness: number
  color: string

}

interface SubtitleFontStyle {

  size: number
  bold: boolean
  italic: boolean

}

@Component
struct AdvancedSubtitleV3 {

  @Prop
  @Require
  surfaceWidth: number
  @Prop
  @Require
  surfaceHeight: number
  @Prop
  @Require
  assFile: CompiledASS
  @Prop
  @Require
  dialogue: Dialogue
  @Link
  currentPosition: number

  @State
  renderingObjects: SubtitleFragments = []

  private canvasHelper: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true), LengthMetricsUnit.PX)

  build() {
    Stack() {
      Canvas(this.canvasHelper) // 这个 canvas 是专门用来计算的
        .height("100%")
        .width("100%")
        .onReady(() => {
          this.rearrange()
        })
      ForEach(this.renderingObjects, (fragment: SubtitleV3Fragment) => {
        AdvancedSubtitleV3SubNode({
          fragment: fragment,
          pos: fragment.movement == undefined ? fragment.position : {
            x: fragment.movement.fromX + ((fragment.movement.toX - fragment.movement.fromX) *
              ((this.currentPosition - fragment.movement.start) / (fragment.movement.end - fragment.movement.start))),
            y: fragment.movement.fromY + ((fragment.movement.toY - fragment.movement.fromY) *
              ((this.currentPosition - fragment.movement.start) / (fragment.movement.end - fragment.movement.start)))
          }
        })
      })
    }
    .height("100%")
    .width("100%")
  }

  rearrange() {
    let renderables: SubtitleV3Fragment[] = [];
    let dialogueStyle = this.assFile.styles[this.dialogue.style];
    for (let slice of this.dialogue.slices) {
      let style = (this.assFile.styles[slice.style] || dialogueStyle)

      let basePrimaryColor = abgrColorStr2argbColor(style.style.PrimaryColour.substring(2) || "00ffffff")
      let baseOutlineColor = abgrColorStr2argbColor(style.style.OutlineColour.substring(2) || "00ffffff")

      let alignPoint = findAlignmentPoint(this.dialogue.alignment, { width: this.surfaceWidth, height: this.surfaceHeight})

      let originPoint: Position
      if (this.dialogue.org == undefined) {
        originPoint = alignPoint
      } else {
        originPoint = scenePointToActual(this.assFile, findOrg(this.dialogue)!, { width: this.surfaceWidth, height: this.surfaceHeight})
      }

      let baseDecoration: SubtitleDecoration = {
        underlined: style.style.Underline == -1,
        strikethrough: style.style.StrikeOut == -1
      }
      let baseOutline: SubtitleOutline | undefined = undefined

      if (style.style.BorderStyle == 1 && style.style.Outline > 0) {
        baseOutline = {
          thickness: style.style.Outline,
          color: baseOutlineColor
        }
      }

      let baseMatrix: matrix4.Matrix4Transit = matrix4.identity()

      baseMatrix = baseMatrix.rotate({
        x: 0,
        y: 0,
        z: 1,
        centerX: originPoint.x,
        centerY: originPoint.y,
        angle: -style.style.Angle
      })

      let relatedOriginPoint: Position = {
        x: originPoint.x / this.surfaceWidth,
        y: originPoint.y / this.surfaceHeight
      }

      let baseRotation: SubtitleRotation = {
        x: {
          centerX: relatedOriginPoint.x,
          centerY: relatedOriginPoint.y,
          angle: 0
        },
        y: {
          centerX: relatedOriginPoint.x,
          centerY: relatedOriginPoint.y,
          angle: 0
        },
        z: {
          centerX: relatedOriginPoint.x,
          centerY: relatedOriginPoint.y,
          angle: -style.style.Angle
        }
      }

      let previousTotalWidth = 0
      let baseStyle: SubtitleFontStyle = {
        size: style.style.Fontsize || 60,
        bold: style.style.Bold == -1,
        italic: style.style.Italic == -1
      }

      let sizes: Size[] = findTotalSizes(this.canvasHelper, style, slice)

      let totalWidth: number = 0
      let totalHeight: number = 0

      for (let size of sizes) {
        totalWidth += size.width
        if (size.height > totalHeight) {
          totalHeight = size.height
        }
      }

      let basePoint: Position
      if (this.dialogue.pos != undefined) {
        basePoint = scenePointToActual(this.assFile, { x: this.dialogue.pos.x, y: this.dialogue.pos.y}, { width: this.surfaceWidth, height: this.surfaceHeight})
      } else {
        basePoint = findBasePosition(this.dialogue.alignment, alignPoint, { width: totalWidth, height: totalHeight })
        if (this.dialogue.alignment == 1 || this.dialogue.alignment == 4 || this.dialogue.alignment == 7) {
          basePoint.x += this.dialogue.margin.left
        }
        if (this.dialogue.alignment == 3 || this.dialogue.alignment == 6 || this.dialogue.alignment == 9) {
          basePoint.x -= this.dialogue.margin.right
        }
        if (this.dialogue.alignment >= 1 && this.dialogue.alignment <= 3) {
          basePoint.y -= this.dialogue.margin.vertical
        } else if (this.dialogue.alignment >= 7 && this.dialogue.alignment <= 0) {
          basePoint.y += this.dialogue.margin.vertical
        }
      }

      let movement: SubtitleMovement | undefined = undefined

      if (this.dialogue.move != undefined) {
        movement = {
          start: this.dialogue.start * 1000,
          end: this.dialogue.end * 1000,
          fromX: this.dialogue.move.x1,
          fromY: this.dialogue.move.y1,
          toX: this.dialogue.move.x2,
          toY: this.dialogue.move.y2
        }
      }

      for (let i = 0; i < slice.fragments.length; i++) {
        let fragment = slice.fragments[i]
        console.error(`origin point: ${originPoint.x}, ${originPoint.y} text: ${fragment.text}`)
        let sizeInfo = sizes[i]
        this.canvasHelper.reset()
        let copiedStyle: SubtitleFontStyle = {
          size: baseStyle.size,
          bold: baseStyle.bold,
          italic: baseStyle.italic
        }
        let copiedPrimaryColor = basePrimaryColor
        let copiedOutlineColor = baseOutlineColor

        let copiedDecoration: SubtitleDecoration = {
          underlined: baseDecoration.underlined,
          strikethrough: baseDecoration.strikethrough
        }
        let copiedOutline: SubtitleOutline | undefined = baseOutline == undefined ? undefined : {
          thickness: baseOutline.thickness,
          color: baseOutlineColor
        }

        let copiedMatrix = baseMatrix.copy()

        let copiedRotation: SubtitleRotation = {
          x: {
            centerX: baseRotation.x.centerX,
            centerY: baseRotation.x.centerY,
            angle: baseRotation.x.angle
          },
          y: {
            centerX: baseRotation.y.centerX,
            centerY: baseRotation.y.centerY,
            angle: baseRotation.y.angle
          },
          z: {
            centerX: baseRotation.z.centerX,
            centerY: baseRotation.z.centerY,
            angle: baseRotation.z.angle
          }
        }

        if (fragment.tag.fs != undefined) {
          copiedStyle.size = fragment.tag.fs
        }
        if (fragment.tag.b != undefined) {
          copiedStyle.bold = fragment.tag.b == 1
        }
        if (fragment.tag.i != undefined) {
          copiedStyle.italic = fragment.tag.i == 1
        }
        if (fragment.tag.c1 != undefined) {
          copiedPrimaryColor = bgrColorStr2rgbColor(fragment.tag.c1)
        }
        if (fragment.tag.c3 != undefined) {
          copiedOutlineColor = bgrColorStr2rgbColor(fragment.tag.c3)
        }
        if (fragment.tag.frx != null) {
          copiedMatrix = copiedMatrix.rotate({
            x: 1,
            y: 0,
            z: 0,
            centerX: originPoint.x,
            centerY: originPoint.y,
            angle: -fragment.tag.frx
          })
          copiedRotation.x.angle -= fragment.tag.frx
        }
        if (fragment.tag.fry != null) {
          copiedMatrix = copiedMatrix.rotate({
            x: 0,
            y: 1,
            z: 0,
            centerX: originPoint.x,
            centerY: originPoint.y,
            angle: -fragment.tag.fry
          })
          copiedRotation.y.angle -= fragment.tag.fry
        }
        if (fragment.tag.frz != null) {
          copiedMatrix = copiedMatrix.rotate({
            x: 0,
            y: 0,
            z: 1,
            centerX: originPoint.x,
            centerY: originPoint.y,
            angle: -fragment.tag.frz
          })
          copiedRotation.z.angle -= fragment.tag.frz
        }
        if (fragment.tag.xbord != undefined && fragment.tag.ybord != undefined) {
          if (!(fragment.tag.xbord > 0 && fragment.tag.ybord > 0)) {
            copiedOutline = undefined
          } else {
            let borderSize = fragment.tag.xbord > fragment.tag.ybord ? fragment.tag.xbord : fragment.tag.ybord
            if (copiedOutline == undefined) {
              copiedOutline = {
                thickness: borderSize,
                color: copiedOutlineColor
              }
            } else {
              copiedOutline.thickness = borderSize
            }
          }
        } else if (fragment.tag.xbord != undefined && fragment.tag.xbord < 1) {
          copiedOutline = undefined
        } else if (fragment.tag.ybord != undefined && fragment.tag.ybord < 1) {
          copiedOutline = undefined
        }
        if (copiedOutline != undefined) {
          copiedOutline.color = copiedOutlineColor
        }

        this.canvasHelper.font = buildFont(copiedStyle)
        renderables.push({
          text: fragment.text,
          font: copiedStyle,
          color: copiedPrimaryColor,
          outline: copiedOutline,
          decoration: copiedDecoration,
          size: sizeInfo,
          position: {
            x: basePoint.x + previousTotalWidth,
            y: basePoint.y
          },
          movement: movement,
          rotation: copiedRotation,
          matrix: copiedMatrix
        })
        previousTotalWidth += this.canvasHelper.measureText(fragment.text).width
      }
    }
    this.renderingObjects.push(...renderables)
  }

}

@Component
struct AdvancedSubtitleV3SubNode {
  @Prop
  @Require
  fragment: SubtitleV3Fragment

  @Prop
  @Require
  @Watch("onPosUpdate")
  pos: Position

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings, LengthMetricsUnit.PX)

  onPosUpdate(propName: string): void {
    this.redraw()
  }

  build() {
    Stack() { // x 轴旋转
      Stack() { // y 轴旋转
        Stack() { // z 轴旋转
          Canvas(this.context)
            .width('100%')
            .height('100%')
            .onReady(() => {
              this.redraw()
            })
        }
        .rotate({
          x: 0,
          y: 0,
          z: 1,
          angle: this.fragment.rotation.z.angle,
          centerX: `${this.fragment.rotation.z.centerX}%`,
          centerY: `${this.fragment.rotation.z.centerY}%`
        })
        .width('100%')
        .height('100%')
      }
      .rotate({
        x: 0,
        y: 1,
        z: 0,
        angle: this.fragment.rotation.y.angle,
        centerX: `${this.fragment.rotation.y.centerX}%`,
        centerY: `${this.fragment.rotation.y.centerY}%`
      })
      .width('100%')
      .height('100%')
    }
    .rotate({
      x: 1,
      y: 0,
      z: 0,
      angle: this.fragment.rotation.x.angle,
      centerX: `${this.fragment.rotation.x.centerX}%`,
      centerY: `${this.fragment.rotation.x.centerY}%`
    })
    .width('100%')
    .height('100%')
  }

  private redraw() {
    this.context.reset()
    this.context.font = buildFont(this.fragment.font)
    if (this.fragment.outline != undefined) {
      this.context.lineWidth = this.fragment.outline.thickness
      this.context.strokeStyle = this.fragment.outline.color.toString()
      this.context.strokeText(this.fragment.text, this.pos.x || 0, this.pos.y || 0)
      if (this.fragment.decoration.underlined) {
        this.context.strokeRect(this.pos.x, this.pos.y, this.fragment.size.width, 2)
      }
      if (this.fragment.decoration.strikethrough) {
        this.context.strokeRect(this.pos.x, this.pos.y - (this.fragment.size.height / 2), this.fragment.size.width, 2)
      }
    }
    this.context.lineWidth = 1
    this.context.fillStyle = this.fragment.color.toString()
    this.context.fillText(this.fragment.text, this.pos.x || 0, this.pos.y || 0)
    if (this.fragment.decoration.underlined) {
      this.context.fillRect(this.pos.x, this.pos.y, this.fragment.size.width, 2)
    }
    if (this.fragment.decoration.strikethrough) {
      this.context.fillRect(this.pos.x, this.pos.y - (this.fragment.size.height / 2), this.fragment.size.width, 2)
    }
  }

}

function buildFont(style: SubtitleFontStyle): string {
  return `${style.italic ? "italic" : "normal"} ${style.bold ? "bold" : "normal"} ${style.size}px`
}

function scenePointToActual(assFile: CompiledASS, scenePosition: Position, actualSize: Size): Position {
  return {
    x: scenePosition.x * (actualSize.width / assFile.width),
    y: scenePosition.y * (actualSize.height / assFile.height)
  }
}

function findTotalSizes(context: CanvasRenderingContext2D, style: CompiledASSStyle, slice: DialogueSlice): Size[] {
  let baseStyle: SubtitleFontStyle = {
    size: style.style.Fontsize || 60,
    bold: style.style.Bold == -1,
    italic: style.style.Italic == -1
  }

  let sizes: Size[] = []

  for (let fragment of slice.fragments) {
    context.reset()

    let copiedStyle: SubtitleFontStyle = {
      size: baseStyle.size,
      bold: baseStyle.bold,
      italic: baseStyle.italic
    }

    if (fragment.tag.fs != undefined) {
      copiedStyle.size = fragment.tag.fs
    }
    if (fragment.tag.b != undefined) {
      copiedStyle.bold = fragment.tag.b == 1
    }
    if (fragment.tag.i != undefined) {
      copiedStyle.italic = fragment.tag.i == 1
    }

    context.font = buildFont(copiedStyle)
    let textMetrics = context.measureText(fragment.text)

    sizes.push({
      width: textMetrics.width,
      height: textMetrics.height
    })
  }

  return sizes
}

function findBasePosition(alignment: number, alignPoint: Position, totalSize: Size): Position {
  let x: number = alignPoint.x
  let y: number = alignPoint.y
  if (alignment == 2) {
    x -= totalSize.width / 2
  } else if (alignment == 3) {
    x -= totalSize.width
  } else if (alignment == 4) {
    y += totalSize.height / 2
  } else if (alignment == 5) {
    x -= totalSize.width / 2
    y += totalSize.height / 2
  } else if (alignment == 6) {
    x -= totalSize.width
    y += totalSize.height / 2
  } else if (alignment == 7) {
    y += totalSize.height
  } else if (alignment == 8) {
    x -= totalSize.width / 2
    y += totalSize.height
  } else if (alignment == 9) {
    x -= totalSize.width
    y += totalSize.height
  }
  return {
    x: x,
    y: y
  }
}

function findAlignmentPoint(alignment: number, actualSize: Size): Position {
  let x: number
  let y: number
  if (alignment == 1) {
    // 1 是左下角
    // x 定位为最左边，所以为 0
    // y 定位为最下面，所以为画布高度
    x = 0
    y = actualSize.height
  } else if (alignment == 2) {
    // 2 是下方向中对齐
    // x 定位为中间，为画布宽度减半，但是文字对齐点是文本左下角，所以横向要减去半个文本宽度才能将文本定位在中间
    // y 参考 1
    x = actualSize.width / 2
    y = actualSize.height
  } else if (alignment == 3) {
    // 3 是右下角
    // x 定位为最右边，为画布宽度，但是文字对齐点是文本左下角，所以横向要减去一个文本宽度才能将文本定位在右边
    // y 参考 1
    x = actualSize.width
    y = actualSize.height
  } else if (alignment == 4) {
    // 4 为中间向左对齐
    // x 参考 1
    // y 定位为中间，为画布高度减半，但文字对齐是左下角，所以竖向要加上半个高度才能将文本定位在中间
    x = 0
    y = actualSize.height / 2
  } else if (alignment == 5) {
    // 5 为画布最中间
    // x 参考 2
    // y 参考 4
    x = actualSize.width / 2
    y = actualSize.height / 2
  } else if (alignment == 6) {
    // 6 为中间向右对齐
    // x 参考 3
    // y 参考 4
    x = actualSize.width
    y = actualSize.height / 2
  } else if (alignment == 7) {
    // 7 为左上角
    // x 参考 1
    // y 定位为最顶部，为 0，但因为文字有高度，所以竖向上要加一个文本高度
    x = 0
    y = 0
  } else if (alignment == 8) {
    // 8 为画布上方相中对齐
    // x 参考 2
    // y 参考 7
    x = actualSize.width / 2
    y = 0
  } else if (alignment == 9) {
    // 9 为右上角
    // x 参考 3
    // y 参考 7
    x = actualSize.width
    y = 0
  } else {
    // 理论上不会出现这个情况
    x = 0
    y = 0
  }
  return {
    x: x,
    y: y
  }
}

function findOrg(dialogue: Dialogue): Position | undefined {
  if (dialogue.org != undefined) {
    return dialogue.org
  }
  return undefined
}
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
          /**
           * 将对话中所有的 slice 进行循环，目前还没有看到要让所有 slice 同时渲染的必要，所以为了方便处理先分开渲染
           */
          ForEach(dialogue.slices, (slice: DialogueSlice) => {
            /**
             * 铺平整个画面
             */
            Column() {
              /**
               * 显示字幕
               */
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
                style: this.dialogueStyles[slice.style] || this.dialogueStyles[dialogue.style]
              })
            }
            .height("100%")
            .width("100%")
            .zIndex(dialogue.layer)
          })
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
    let baseStyle = `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" : "normal"} ${this.style?.style.Fontsize || 60}px`

    // 用于计算字幕大小，以确定左下角的位置
    let totalWidth = 0
    let totalHeight = 0

    // 将所有的 fragment 循环，计算加在一起的总长度，因为 fragment 其实是同一个对话但是对不同位置的文字进行了不同程度的标签覆写导致的碎片文本
    for (let fragment of this.slice.fragments) {
      this.context.font = baseStyle
      // 如果这个碎片文本的标签中有字体大小的修改，实际上这个 fs 改的是行高，但是 Canvas 没法修改，只能修改字体大小
      if (fragment.tag.fs != undefined) {
        this.context.font = `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" : "normal"} ${fragment.tag.fs}px`
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
      console.error(`displaying subtitle content (${fragment.text}) at ${x + previousWidth}, ${y} with color ${abgrColorStr2argbColor(this.style?.style.PrimaryColour.substring(2) || "00ffffff")}`)
      this.context.font = baseStyle
      // 如果文本碎片的标签修改了文字大小，修改上下文的字体
      if (fragment.tag.fs) {
        this.context.font = `${this.style?.style.Italic == -1 ? "italic" : "normal"} ${this.style?.style.Bold == -1 ? "bold" : "normal"} ${fragment.tag.fs}px`
      }
      // 确保边框是否应该显示
      if (fragment.tag.xbord || 1 > 0 && fragment.tag.ybord || 1 > 0) {
        if (this.style?.style.BorderStyle == 1 && this.style?.style.OutlineColour.length == 10) {
          // 如果文本碎片的标签修改了描边的颜色
          if (fragment.tag.c3 != undefined) {
            this.context.strokeStyle = `#${fragment.tag.c3}`
          } else {
            this.context.strokeStyle = abgrColorStr2argbColor(this.style?.style.OutlineColour.substring(2) || "00ffffff")
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
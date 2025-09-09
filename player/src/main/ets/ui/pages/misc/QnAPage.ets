import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { InnerContainerText } from '../../component/inner/InnerContainerText'
import { InnerDivider } from '../../component/inner/InnerDivider'
import { InnerFoldable } from '../../component/inner/InnerFoldable'

@ComponentV2
export struct QnAPage {
  @Consumer("indexNavigator")
  private indexNavigator: NavPathStack = new NavPathStack()

  build() {
    NavDestination() {
      InnerContainer() {
        InnerComponentSet() {
          InnerFoldable({
            title: "PGS 字幕问题"
          }) {
            Text() {
              Span("可能您已经遇到了如下问题：\n")
              Span("  PGS 字幕有延迟或者提前的问题；\n")
              Span("  开启 PGS 字幕后 UI 有时候会卡顿；\n\n")
              Span("由于目前没有一个好的 PGS 字幕解析库，只能在用户选择播放 PGS 字幕后直接一股脑的把字幕文件全部读取了，而 PGS 字幕实际上是直接存储的字幕的图片而非文字，所以远比一般的字幕文件（.ass 格式、.srt 格式）要大的多得多，所以一次性读取的开销很大，就会导致软件卡顿。\n")
              Span("同时由于一般情况下视频每隔几秒就会刷新到下一段字幕，就要不断的读取字幕的图片并进行渲染，这一过程中有概率卡死线程导致触发系统的冻结保护而导致崩溃。\n")
              Span("为了尽可能防止冻结保护导致崩溃，因此 Rohy 播放器通过异步来处理字幕图片，这一方式又有一定几率导致字幕的提前或延迟。\b")
              Span("所以目前 PGS 字幕体验可能不佳。")
            }
            .width("100%")
          }
          InnerDivider()
          InnerFoldable({
            title: "支持哪些视频编码？"
          }) {
            Text("目前支持 H.263，H.264，H.265，H.266，MPEG2，MPEG4 等编码格式，其中 H.264，H.265，H.266 支持硬件解码。未来会支持更多的编码格式。")
              .width("100%")
          }
          InnerDivider()
          InnerFoldable({
            title: "会支持 HDR 吗？"
          }) {
            Text("会的。虽然 HarmonyOS 本身就有对 HDRVivid 的支持，但 Rohy 播放器还没有做相关支持。对于其他的 HDR 格式类似杜比视野，将会在未来支持。")
              .width("100%")
          }
          InnerDivider()
          InnerFoldable({
            title: "有时候打开软件主页为空，播放列表都不见了"
          }) {
            Text("播放列表没有丢失，只是加载失败了，重新加载一下即可。")
              .width("100%")
          }
        }
/*
        InnerContainerDivider()
        InnerContainerText({
          text: "未来的开发计划"
        })
        InnerComponentSet() {
          InnerFoldable({
            title: "0.4.0 PC 体验完善"
          }) {
            Text() {
              Span("· 支持导入 WebDAV 服务器。\n")
              Span("· 为 PC 用户支持基础播放列表功能。\n")
              Span("· 为 平板/PC 用户支持直接导入文件夹进行扫描的功能。\n")
              Span("· 支持字体管理功能。\n")
              Span("· 支持自定义控件的模糊效果。\n")
              Span("· 为 PC 底部栏添加两种显示模式：范围内显示（鼠标在底部栏范围内才显示）| 移动鼠标显示（鼠标只要移动就显示）。\n")
              Span("· 播放列表中顶部显示一个地址栏，可以点击直接跳转回更高层级的文件夹页。例：播放列表A > 文件夹B > 文件夹C，可以点击”播放列表A“直接回到播放列表根目录。\n")
              Span("· 播放列表管理的时候可以打开多选进行批量操作，如删除、移动。\n")
              Span("· 支持为导入到播放列表内的视频导入外部字幕（可永久性使用）。\n")
              Span("· 播放列表内的视频支持连续播放。\n")
              Span("· 添加“上一个”和“下一个”按钮可以直接在播放列表内直接切换前后的视频。")
            }
          }

          InnerDivider()
          InnerFoldable({
            title: "0.5.0 UI 革新"
          }) {
            Text() {
              Span("· 对大部分 UI 进行一波重新设计与优化。\n")
              Span("· 调整配色方案，使深色模式下的配色有正常的辨识度。\n")
              Span("· 修改底部栏和顶部栏的 UI 效果，去除背景，将原本背景的效果直接应用于控件。\n")
              Span("· 为缺失动画效果的控件添加动画效果。\n")
              Span("· 添加搜索功能，允许搜索播放列表内的视频，结果显示的时候将以播放列表分块显示，支持正则、支持筛选文件夹和视频。\n")
              Span("· 支持流转。")
            }
          }

          InnerDivider()
          InnerFoldable({
            title: "0.6.0 内核革新"
          }) {
            Text() {
              Span("· 替换 IJKPlayer 为 RohyPlayer（W.I.P.）。\n")
              Span("· 支持硬件解码。\n")
              Span("· 支持选择优先的解码器（硬件解码仅支持 ohcodec 解码，其他的可以选择优先使用 ffmpeg 解码还是 ohcodec 解码）。\n")
              Span("· 支持 HDR Vivid。\n")
              Span("· 支持 Audio Vivid。\n")
              Span("· 支持调整音轨播放偏移量（延迟 0.5s，加快 0.5s）。\n")
              Span("· 支持调整字幕播放偏移量（延迟 0.5s，加快 0.5s）。\n")
              Span("· 支持导入额外的音轨。\n")
              Span("· 视频滤镜功能。\n")
              Span("· 音频均衡器功能。")
            }
          }
        }*/
      }
    }
    .backgroundColor($r("app.color.rohy_background"))
    .hideTitleBar(false)
    .hideToolBar(true)
    .hideBackButton(false)
    .title($r("app.string.questions"))
    .width("100%")
    .height("100%")
  }
}
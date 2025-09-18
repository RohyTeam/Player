import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { InnerContainerText, InnerContainerTextCustomizable } from '../../component/inner/InnerContainerText'
import { InnerDivider } from '../../component/inner/InnerDivider'
import { InnerFoldable } from '../../component/inner/InnerFoldable'
import { InnerSelect } from '../../component/inner/InnerSelect'

@ComponentV2
export struct DecodersPage {

  build() {
    InnerContainer({
      scrollBar: false,
      fillHeight: true
    }) {
      InnerContainerTextCustomizable() {
        SymbolSpan($r('sys.symbol.exclamationmark_circle'))
        Span(" ")
        Span($r('app.string.decoders_tips'))
      }
      InnerContainerDivider()
      InnerContainerText({
        text: "视频解码器"
      })
      InnerComponentSet() {
        InnerSelect({
          title: "H.264 (AVC)",
          sameId: 'decoders',
          choices: [
            {
              title: "硬件解码器",
              action: () => {}
            },
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "H.265 (HEVC)",
          sameId: 'decoders',
          choices: [
            {
              title: "硬件解码器",
              action: () => {}
            },
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "H.266 (VVC)",
          sameId: 'decoders',
          choices: [
            {
              title: "硬件解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "H.263",
          sameId: 'decoders',
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "MPEG-2",
          sameId: 'decoders',
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "MPEG-4",
          sameId: 'decoders',
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
      }
      InnerContainerDivider()
      InnerContainerText({
        text: "音频解码器"
      })
      InnerComponentSet() {
        InnerSelect({
          title: "AAC",
          sameId: 'decoders',
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "MPEG (MP3)",
          sameId: 'decoders',
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "FLAC",
          sameId: 'decoders',
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "Vorbis",
          sameId: 'decoders',
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "OPUS",
          sameId: 'decoders',
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码",
              action: () => {}
            }
          ]
        })
      }
    }
  }
}
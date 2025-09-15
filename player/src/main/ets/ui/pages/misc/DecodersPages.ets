import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerContainerDivider } from '../../component/inner/InnerContainerDivider'
import { InnerContainerText } from '../../component/inner/InnerContainerText'
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
      InnerContainerText({
        text: "视频解码器"
      })
      InnerComponentSet() {
        InnerSelect({
          title: "H.264 (AVC)",
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
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "H.265 (HEVC)",
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
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "H.266 (VVC)",
          choices: [
            {
              title: "硬件解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "H.263",
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "MPEG-2",
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "MPEG-4",
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
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
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "MPEG (MP3)",
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "FLAC",
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "Vorbis",
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
        InnerDivider()
        InnerSelect({
          title: "OPUS",
          choices: [
            {
              title: "系统解码器",
              action: () => {}
            },
            {
              title: "FFmpeg 解码器",
              action: () => {}
            }
          ]
        })
      }
    }
  }
}
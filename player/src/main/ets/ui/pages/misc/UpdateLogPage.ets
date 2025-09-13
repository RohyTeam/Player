import { CJMarkdown } from '@cangjie-tpc/markdown_hybrid'
import { UPDATE_LOG_0001000 } from '../../../update_log/UpdateLog0001000'
import { UPDATE_LOG_0002000 } from '../../../update_log/UpdateLog0002000'
import { UPDATE_LOG_0003000 } from '../../../update_log/UpdateLog0003000'
import { UPDATE_LOG_0003001 } from '../../../update_log/UpdateLog0003001'
import { UPDATE_LOG_0003002 } from '../../../update_log/UpdateLog0003002'
import { UPDATE_LOG_0003003 } from '../../../update_log/UpdateLog0003003'
import { UPDATE_LOG_0003004 } from '../../../update_log/UpdateLog0003004'
import { InnerComponentSet } from '../../component/inner/InnerComponentSet'
import { InnerContainer } from '../../component/inner/InnerContainer'
import { InnerDivider } from '../../component/inner/InnerDivider'
import { InnerFoldable } from '../../component/inner/InnerFoldable'

@ComponentV2
export struct UpdateLogPage {

  build() {
    InnerContainer({
      scrollBar: false,
      fillHeight: true
    }) {
      InnerComponentSet() {
        InnerFoldable({
          title: "v0.3.4"
        }) {
          CJMarkdown({
            mdStr: UPDATE_LOG_0003004,
            isFull: true
          })
            .width("100%")
        }
        InnerDivider()
        InnerFoldable({
          title: "v0.3.3"
        }) {
          CJMarkdown({
            mdStr: UPDATE_LOG_0003003,
            isFull: true
          })
            .width("100%")
        }
        InnerDivider()
        InnerFoldable({
          title: "v0.3.2"
        }) {
          CJMarkdown({
            mdStr: UPDATE_LOG_0003002,
            isFull: true
          })
            .width("100%")
        }
        InnerDivider()
        InnerFoldable({
          title: "v0.3.1"
        }) {
          CJMarkdown({
            mdStr: UPDATE_LOG_0003001,
            isFull: true
          })
            .width("100%")
        }
        InnerDivider()
        InnerFoldable({
          title: "v0.3.0"
        }) {
          CJMarkdown({
            mdStr: UPDATE_LOG_0003000,
            isFull: true
          })
            .width("100%")
        }
        InnerDivider()
        InnerFoldable({
          title: "v0.2.0"
        }) {
          CJMarkdown({
            mdStr: UPDATE_LOG_0002000,
            isFull: true
          })
            .width("100%")
        }
        InnerDivider()
        InnerFoldable({
          title: "v0.1.0"
        }) {
          CJMarkdown({
            mdStr: UPDATE_LOG_0001000,
            isFull: true
          })
            .width("100%")
        }
      }
    }
  }
}
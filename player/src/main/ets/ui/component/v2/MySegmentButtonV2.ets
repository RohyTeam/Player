import { SegmentButton, SegmentButtonOptions } from '@kit.ArkUI'

export interface MySegmentCallback {

  callback: (index: number) => void

}

@Component
export struct MySegmentButtonV2 {
  @Prop
  @Require
  options: SegmentButtonOptions
  @Prop
  @Require
  selected: number
  @Prop
  @Require
  callback: MySegmentCallback
  @State
  realSelected: number[] = [this.selected]

  build() {
    SegmentButton({
      options: this.options,
      selectedIndexes: this.realSelected,
      onItemClicked: (index) => {
        this.callback.callback(index)
      }
    })
  }
}
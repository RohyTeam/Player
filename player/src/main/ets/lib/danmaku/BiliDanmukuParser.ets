/*
 * Copyright (C) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { BaseDanmaku }from '@ohos/danmakuflamemaster';
import { Duration }from '@ohos/danmakuflamemaster';
import { IDisplayer }from '@ohos/danmakuflamemaster';
import { SpecialDanmaku }from '@ohos/danmakuflamemaster';
import { Danmakus }from '@ohos/danmakuflamemaster';
import { BaseDanmakuParser }from '@ohos/danmakuflamemaster';
import { DanmakuFactory }from '@ohos/danmakuflamemaster';
import { DanmakuUtils }from '@ohos/danmakuflamemaster';
import { IDanmakus, ST_BY_TIME }from '@ohos/danmakuflamemaster';

export class BiliDanmukuParser extends BaseDanmakuParser {
  private sourceDanmakus = []
  protected mDispScaleX: number =0;
  protected mDispScaleY: number = 0;

  parse(): IDanmakus|ESObject{
    class danmakus {
      sortType: number = 0
      duplicateMergingEnabled: boolean = false
      baseComparator: ESObject
    }
    if(this.mDataSource!=null){
      let args:danmakus = { sortType: ST_BY_TIME,
        duplicateMergingEnabled: false,
        baseComparator: this.mContext.getBaseComparator()}
      let result: Danmakus = new Danmakus((args) as ESObject)

      this.mDataSource.data().forEach((sourceItem:ESObject) => {
        let item:SpecialDanmaku = this.mContext.mDanmakuFactory.createDanmakuByContext(Number(sourceItem.DanmakuType), this.mContext)
        if (item != null) {
          item.setTime(Number.parseFloat(sourceItem.time))
          item.textSize = Number.parseFloat(sourceItem.textSize) * (this.mDispDensity * 0.8)
          item.textColor = Number(sourceItem.textColor)
          item.textShadowColor = Number(sourceItem.textShadowColor)


          item.text = sourceItem.text
          item.index = Number(sourceItem.index)
          DanmakuUtils.fillText(item, item.text);
          if (Number(sourceItem.DanmakuType) == BaseDanmaku.TYPE_SPECIAL) {
            item.duration = new Duration(Number.parseFloat(sourceItem.duration))
            item.rotationZ = Number.parseFloat(sourceItem.rotationZ)
            item.rotationY = Number.parseFloat(sourceItem.rotationY)

            this.mContext.mDanmakuFactory.fillTranslationData(item,
              Number.parseFloat(sourceItem.beginX),
              Number.parseFloat(sourceItem.beginY),
              Number.parseFloat(sourceItem.endX),
              Number.parseFloat(sourceItem.endY),
              Number.parseFloat(sourceItem.translationDuration),
              Number.parseFloat(sourceItem.translationStartDelay),
              this.mDispScaleX, this.mDispScaleY)
            this.mContext.mDanmakuFactory.fillAlphaData(item,
              Number(sourceItem.beginAlpha),
              Number(sourceItem.endAlpha),
              Number.parseFloat(sourceItem.alphaDuration));
            (item as SpecialDanmaku).isQuadraticEaseOut = Boolean((sourceItem.isQuadraticEaseOut)as boolean)

          }

        }

        if (item.text != null) {
          if (item.duration != null) {
            item.setTimer(this.mTimer);
            item.flags = this.mContext.mGlobalFlagValues
            result.addItem(item)
          }
        }
      })
      return result
    }



  }

  setDisplayer(disp: IDisplayer) {
    super.setDisplayer(disp)
    this.mDispScaleX = this.mDispWidth / DanmakuFactory.BILI_PLAYER_WIDTH;
    this.mDispScaleY = this.mDispHeight / DanmakuFactory.BILI_PLAYER_HEIGHT;
    return this
  }
}
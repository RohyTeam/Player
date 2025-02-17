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

export class MessageType {

  static MEDIA_PREPARED: number= 1;

  static MEDIA_PLAYBACK_COMPLETE: number= 2;

  static MEDIA_BUFFERING_UPDATE: number= 3;

  static MEDIA_SEEK_COMPLETE: number= 4;

  static MEDIA_SET_VIDEO_SIZE: number= 5;

  static MEDIA_TIMED_TEXT: number= 99;

  static MEDIA_ERROR: number= 100;

  static MEDIA_INFO: number= 200;

  static MEDIA_AUDIO_INTERRUPT:number = 201;

  static MEDIA_AUDIO_DEVICE_CHANGE:number = 202;

  static MEDIA_SET_VIDEO_SAR:number = 10001;

}

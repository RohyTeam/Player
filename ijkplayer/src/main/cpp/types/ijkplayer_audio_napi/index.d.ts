/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
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
export declare class newIjkPlayerAudio {
  public Id: string;
  public isVideo: boolean;
  constructor(Id: string, isVideo: boolean);
  _native_setup_audio(xcomponentId: string): void;
  _nativeOpenlog(xcomponentId: string): void;
  _setDataSource(xcomponentId: string, url:string): void;
  _setOption(xcomponentId: string, category:string,key:string,value:string): void;
  _setOptionLong(xcomponentId: string, category:string,key:string,value:string): void;
  _prepareAsync(xcomponentId: string): void;
  _start(xcomponentId: string): void;
  _stop(xcomponentId: string): void;
  _pause(xcomponentId: string): void;
  _reset(xcomponentId: string): void;
  _release(xcomponentId: string): void;
  _seekTo(xcomponentId: string, msec:string): void;
  _isPlaying(xcomponentId: string): boolean;
  _getDuration(xcomponentId: string): number;
  _setMessageListener(xcomponentId: string, messageCallBack:Function): void;
  _getCurrentPosition(xcomponentId: string): number;
  _getAudioSessionId(xcomponentId: string): number;
  _setPropertyFloat(xcomponentId: string, property: string, value: string): void;
  _getPropertyFloat(xcomponentId: string, property: string, value: string): number;
  _setPropertyLong(xcomponentId: string, property: string, value: string): void;
  _getPropertyLong(xcomponentId: string, property: string, value: string): number;
  _setVolume(xcomponentId: string, leftVolume: string, rightVolume: string): void;
  _setLoopCount(xcomponentId: string, loopCount: string): void;
  _getLoopCount(xcomponentId: string): number;
  _setStreamSelected(xcomponentId: string, stream: string, select: string): void;
  _getVideoCodecInfo(xcomponentId: string): string;
  _getAudioCodecInfo(xcomponentId: string): string;
  _getMediaMeta(xcomponentId: string): string;
  _native_setup(xcomponentId: string): void;
}
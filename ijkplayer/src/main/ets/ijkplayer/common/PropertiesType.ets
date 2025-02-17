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

export class PropertiesType {

  static PROP_FLOAT_VIDEO_DECODE_FRAMES_PER_SECOND: string = "10001";

  static PROP_FLOAT_VIDEO_OUTPUT_FRAMES_PER_SECOND: string = "10002";

  static FFP_PROP_FLOAT_PLAYBACK_RATE: string = "10003";

  static FFP_PROP_FLOAT_DROP_FRAME_RATE: string = "10007";

  static FFP_PROP_INT64_SELECTED_VIDEO_STREAM: string = "20001";

  static FFP_PROP_INT64_SELECTED_AUDIO_STREAM: string = "20002";

  static FFP_PROP_INT64_SELECTED_TIMEDTEXT_STREAM: string = "20011";

  static FFP_PROP_INT64_VIDEO_DECODER: string = "20003";

  static FFP_PROP_INT64_AUDIO_DECODER: string = "20004";

  static FFP_PROPV_DECODER_UNKNOWN: string = "0";

  static FFP_PROPV_DECODER_AVCODEC: string = "1";

  static FFP_PROPV_DECODER_MEDIACODEC: string = "2";

  static FFP_PROPV_DECODER_VIDEOTOOLBOX: string = "3";

  static FFP_PROP_INT64_VIDEO_CACHED_DURATION: string = "20005";

  static FFP_PROP_INT64_AUDIO_CACHED_DURATION: string = "20006";

  static FFP_PROP_INT64_VIDEO_CACHED_BYTES: string = "20007";

  static FFP_PROP_INT64_AUDIO_CACHED_BYTES: string = "20008";

  static FFP_PROP_INT64_VIDEO_CACHED_PACKETS: string = "20009";

  static FFP_PROP_INT64_AUDIO_CACHED_PACKETS: string = "20010";

  static FFP_PROP_INT64_ASYNC_STATISTIC_BUF_BACKWARDS: string = "20201";

  static FFP_PROP_INT64_ASYNC_STATISTIC_BUF_FORWARDS: string = "20202";

  static FFP_PROP_INT64_ASYNC_STATISTIC_BUF_CAPACITY: string = "20203";

  static FFP_PROP_INT64_TRAFFIC_STATISTIC_BYTE_COUNT: string = "20204";

  static FFP_PROP_INT64_CACHE_STATISTIC_PHYSICAL_POS: string = "20205";

  static FFP_PROP_INT64_CACHE_STATISTIC_FILE_FORWARDS: string = "20206";

  static FFP_PROP_INT64_CACHE_STATISTIC_FILE_POS: string = "20207";

  static FFP_PROP_INT64_CACHE_STATISTIC_COUNT_BYTES: string = "20208";

  static FFP_PROP_INT64_LOGICAL_FILE_SIZE: string = "20209";

  static FFP_PROP_INT64_SHARE_CACHE_DATA: string = "20210";

  static FFP_PROP_INT64_BIT_RATE: string = "20100";

  static FFP_PROP_INT64_TCP_SPEED: string = "20200";

  static FFP_PROP_INT64_LATEST_SEEK_LOAD_DURATION: string = "20300";

  static FFP_PROP_INT64_IMMEDIATE_RECONNECT: string = "20211";

}

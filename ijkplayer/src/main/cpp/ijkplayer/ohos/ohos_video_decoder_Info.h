/*
 * ohos_video_decoder_Info.h
 *
 * Copyright (C) 2024 Huawei Device Co.,Ltd.
 *
 * This file is part of ijkPlayer.
 *
 * ijkPlayer is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * ijkPlayer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with ijkPlayer; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#ifndef DECODERDEMO_DECODERINFO_H
#define DECODERDEMO_DECODERINFO_H

#include <multimedia/player_framework/native_avbuffer.h>
#include <multimedia/player_framework/native_avbuffer_info.h>
#include <multimedia/player_framework/native_avformat.h>
#include <multimedia/player_framework/native_avmemory.h>
#include <string>

struct FormatInfo {
    int32_t videoWidth {0};
    int32_t videoHeight {0};
    double fps {0};
    OH_AVPixelFormat pixelFormat {AV_PIXEL_FORMAT_NV12};
};

struct CodecBufferInfo {
    CodecBufferInfo() = default;
    CodecBufferInfo(uint32_t index, OH_AVBuffer *buff);
    ~CodecBufferInfo();
    OH_AVCodecBufferAttr attr = {0, 0, 0, AVCODEC_BUFFER_FLAGS_NONE};
    int32_t bufferIndex {0};
    OH_AVBuffer *buff_ {nullptr};
};

#endif // DECODERDEMO_DECODERINFO_H

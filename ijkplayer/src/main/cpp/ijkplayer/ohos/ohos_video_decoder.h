/*
 * ohos_video_decoder.h
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

#ifndef DECODERDEMO_DECODER_H
#define DECODERDEMO_DECODER_H

#include <multimedia/player_framework/native_avcodec_videodecoder.h>
#include <multimedia/player_framework/native_avcapability.h>
#include <multimedia/player_framework/native_avcodec_base.h>
#include <multimedia/player_framework/native_avformat.h>
#include <multimedia/player_framework/native_avbuffer.h>
#include <native_buffer/native_buffer.h>
#include <cstdint>

#include "ohos_video_decoder_data.h"

class VideoDecoder {
public:
    enum class DecodeStat {
        NONE = 0,
        CONFIGUED,
        STOP,
        RUNNING,
        RELEASE,
    };
    VideoDecoder() = default;
    ~VideoDecoder();
    int32_t Create(const char *type);
    int32_t Config(CodecData *codecData);
    int32_t Start();
    int32_t PushInputData(CodecBufferInfo &info);
    int32_t FreeOutputData(uint32_t bufferIndex);
    int32_t Stop();
    void Release();
    const DecodeStat &Stat();
    OH_AVCodec *decoder_{nullptr};
private:
    int32_t Configure(FormatInfo *formatInfo);
    int32_t SetCallback(CodecData *codecData);
    DecodeStat stat{DecodeStat::NONE};
};

#endif // DECODERDEMO_DECODER_H

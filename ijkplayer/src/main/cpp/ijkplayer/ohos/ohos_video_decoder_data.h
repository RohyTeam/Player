/*
 * ohos_video_decoder_data.h
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

#ifndef DECODERDEMO_DECODERDATA_H
#define DECODERDEMO_DECODERDATA_H

#include <multimedia/player_framework/native_avcodec_videoencoder.h>
#include <multimedia/player_framework/native_avbuffer_info.h>
#include <multimedia/player_framework/native_avformat.h>
#include <mutex>
#include <queue>
#include "ohos_video_decoder_Info.h"
#include "ffpipenode_ohos_mediacodec_vdec.h"

class CodecData {
public:
    ~CodecData();
    FormatInfo *formatInfo{nullptr};
    void Start();
    void ShutDown();
    class DataCallback {
    public:
        static void OnCodecError(OH_AVCodec *codec, int32_t errorCode, void *userData);
        static void OnCodecFormatChange(OH_AVCodec *codec, OH_AVFormat *format, void *userData);
        static void OnNeedInputBuffer(OH_AVCodec *codec, uint32_t index, OH_AVBuffer *buffer, void *userData);
        static void OnNewOutputBuffer(OH_AVCodec *codec, uint32_t index, OH_AVBuffer *buffer, void *userData);
    };
    uint32_t inputFrameCount_{0};
    uint32_t outputFrameCount_{0};
    int32_t InputData(CodecBufferInfo &info, std::chrono::milliseconds time);
    bool OutputData(CodecBufferInfo &receiveInfo);
private:
    std::mutex inputMutex_;
    std::condition_variable inputCond_;
    std::queue<CodecBufferInfo> inputBufferInfoQueue_;
    std::mutex outputMutex_;
    std::condition_variable outputCond_;
    std::queue<CodecBufferInfo> outputBufferInfoQueue_;
    int awaitTime_ = 4;
};

#endif // DECODERDEMO_DECODERDATA_H

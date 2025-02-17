/*
 * ohos_video_decoder_data.cpp
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

#include <multimedia/player_framework/native_averrors.h>
#include "hilog/log.h"
#include "ohos_video_decoder_data.h"

CodecData::~CodecData()
{
    CodecData::ShutDown();
    formatInfo = nullptr;
    inputFrameCount_ = 0;
    outputFrameCount_ = 0;
}

void CodecData::Start()
{
    inputCond_.notify_all();
    outputCond_.notify_all();
}

void CodecData::ShutDown()
{
    inputCond_.notify_all();
    outputCond_.notify_all();
}

int32_t CodecData::InputData(CodecBufferInfo &info, std::chrono::milliseconds time)
{
    if (info.buff_ == nullptr || this->formatInfo == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "DecoderData", "info.buff_ or formatInfo nullptr");
        return AV_ERR_UNKNOWN;
    }
    std::unique_lock<std::mutex> lock(this->inputMutex_);
    bool condRet =
        this->inputCond_.wait_for(lock, time, [this]() { return !this->inputBufferInfoQueue_.empty();});

    if (this->inputBufferInfoQueue_.empty()) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "DecoderData", "inputBufferInfoQueue_ is empty");
        return AV_ERR_TIMEOUT;
    }
    CodecBufferInfo bufferInfo = this->inputBufferInfoQueue_.front();
    this->inputBufferInfoQueue_.pop();
    this->inputFrameCount_++;
    lock.unlock();
    auto bufferInfoAddr = OH_AVBuffer_GetAddr(bufferInfo.buff_);
    auto infoAddr = OH_AVBuffer_GetAddr(info.buff_);
    if (bufferInfoAddr == nullptr || infoAddr == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "DecoderData", "ABbuffAddr is nullptr");
        return AV_ERR_IO;
    }
    memcpy(bufferInfoAddr, infoAddr, info.attr.size);
    OH_AVBuffer_SetBufferAttr(bufferInfo.buff_, &info.attr);
    info.bufferIndex = bufferInfo.bufferIndex;
    if (bufferInfo.attr.flags & AVCODEC_BUFFER_FLAGS_EOS) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "DecoderData", "Catch EOS");
        return AV_ERR_OK;
    }
    OH_AVBuffer_Destroy(bufferInfo.buff_);
    return AV_ERR_OK;
}

bool CodecData::OutputData(CodecBufferInfo &receiveInfo)
{
    std::unique_lock<std::mutex> lock(this->outputMutex_);
    bool ret = this->outputCond_.wait_for(lock, std::chrono::milliseconds(awaitTime_), [this]() {
                                              return !this->outputBufferInfoQueue_.empty();
                                          });
    if (!ret) {
        LOGE("OutputData outputBufferInfoQueue_ is empty");
        return false;
    }

    receiveInfo = this->outputBufferInfoQueue_.front();
    this->outputBufferInfoQueue_.pop();
    this->outputFrameCount_++;
    lock.unlock();
    return true;
}

void CodecData::DataCallback::OnCodecError(OH_AVCodec *codec, int32_t errorCode, void *userData)
{
    (void)codec;
    (void)errorCode;
    (void)userData;
    OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "On decoder error, error code: %{public}d", errorCode);
}

void CodecData::DataCallback::OnCodecFormatChange(OH_AVCodec *videoEnc, OH_AVFormat *format, void *userData)
{
    (void)videoEnc;
    (void)format;
    (void)userData;
    if (userData == nullptr) {
        return;
    }
    (void)userData;
    CodecData *codecUserData = static_cast<CodecData *>(userData);
    std::unique_lock<std::mutex> lock(codecUserData->outputMutex_);
}

void CodecData::DataCallback::OnNeedInputBuffer(OH_AVCodec *codec, uint32_t index, OH_AVBuffer *buffer,
    void *userData)
{
    if (userData == nullptr) {
        return;
    }
    (void)codec;
    CodecData *codecUserData = static_cast<CodecData *>(userData);
    std::unique_lock<std::mutex> lock(codecUserData->inputMutex_);
    codecUserData->inputBufferInfoQueue_.emplace(index, buffer);
    codecUserData->inputCond_.notify_all();
}

void CodecData::DataCallback::OnNewOutputBuffer(OH_AVCodec *codec, uint32_t index, OH_AVBuffer *buffer,
    void *userData)
{
    if (userData == nullptr) {
        return;
    }
    (void)codec;
    CodecData *codecUserData = static_cast<CodecData *>(userData);
    std::unique_lock<std::mutex> lock(codecUserData->outputMutex_);
    codecUserData->outputBufferInfoQueue_.emplace(index, buffer);
    codecUserData->outputCond_.notify_all();
}

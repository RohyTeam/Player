/*
 * ohos_video_decoder.cpp
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

#include "hilog/log.h"
#include "ohos_video_decoder.h"

VideoDecoder::~VideoDecoder() { }

int32_t VideoDecoder::Create(const char *type)
{
    OH_AVCapability *capability = OH_AVCodec_GetCapability(type, false);
    const char *name = OH_AVCapability_GetName(capability);
    decoder_ = OH_VideoDecoder_CreateByName(name);
    if (decoder_ == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "OH_VideoDecoder_CreateByName Failed");
        return AV_ERR_UNKNOWN;
    } else {
        stat = DecodeStat::NONE;
        return AV_ERR_OK;
    }
    return 0;
}

int32_t VideoDecoder::Config(CodecData *codecData)
{
    if (decoder_ == nullptr || codecData == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "decoder_ or codecData nullptr");
        return AV_ERR_UNKNOWN;
    }
    int32_t ret = Configure(codecData->formatInfo);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "Configure failed");
        return AV_ERR_UNKNOWN;
    }
    ret = SetCallback(codecData);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "SetCallback failed");
        return AV_ERR_UNKNOWN;
    }
    ret = OH_VideoDecoder_Prepare(decoder_);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "OH_VideoDecoder_Prepare failed");
        return AV_ERR_UNKNOWN;
    }
    return 0;
}

int32_t VideoDecoder::Start()
{
    if (decoder_ == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "decoder_ nullptr");
        return AV_ERR_INVALID_VAL;
    }
    // 启动编码器，开始编码
    int32_t ret = OH_VideoDecoder_Start(decoder_);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "OH_VideoDecoder_Start Failed");
        return AV_ERR_UNKNOWN;
    }
    stat = DecodeStat::RUNNING;
    return ret;
}

int32_t VideoDecoder::PushInputData(CodecBufferInfo &info)
{
    if (decoder_ == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "decoder_ nullptr");
        return AV_ERR_INVALID_VAL;
    }
    int32_t ret = AV_ERR_INVALID_VAL;
    ret = OH_VideoDecoder_PushInputBuffer(decoder_, info.bufferIndex);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "OhosVideoDecoder", "Push input data failed");
        return ret;
    }
    return AV_ERR_OK;
}

int32_t VideoDecoder::FreeOutputData(uint32_t bufferIndex)
{
    if (decoder_ == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "decoder_ nullptr");
        return AV_ERR_INVALID_VAL;
    }
    int32_t ret = AV_ERR_OK;
    ret = OH_VideoDecoder_FreeOutputBuffer(decoder_, bufferIndex);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "OhosVideoDecoder", "OH_VideoDecoder_RenderOutputBuffer failed");
        return ret;
    }
    return ret;
}

int32_t VideoDecoder::Stop()
{
    if (decoder_ == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "decoder_ nullptr");
        return AV_ERR_INVALID_VAL;
    }
    int32_t ret = AV_ERR_INVALID_VAL;
    // 终止解码器videoDec
    ret = OH_VideoDecoder_Stop(decoder_);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "OH_VideoDecoder_Stop Failed");
        return AV_ERR_UNKNOWN;
    }
    ret = OH_VideoDecoder_Flush(decoder_);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "OhosVideoDecoder", "OH_VideoDecoder_Flush Failed");
        return ret;
    }
    stat = DecodeStat::STOP;
    return 0;
}

void VideoDecoder::Release()
{
    int32_t ret = AV_ERR_OK;
    if (decoder_ != nullptr) {
        ret = OH_VideoDecoder_Destroy(decoder_);
        decoder_ = nullptr;
        stat = DecodeStat::RELEASE;
    }
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "OH_VideoDecoder_Destroy Failed");
    }
}

int32_t VideoDecoder::Configure(FormatInfo *formatInfo)
{
    if (decoder_ == nullptr || formatInfo == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "decoder_ or formatInfo nullptr");
        return AV_ERR_INVALID_VAL;
    }
    if (formatInfo->videoWidth == 0 || formatInfo->videoHeight == 0) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "decoder parameter error");
        return AV_ERR_INVALID_VAL;
    }
    OH_AVFormat *format = OH_AVFormat_Create();
    // 写入format
    OH_AVFormat_SetIntValue(format, OH_MD_KEY_WIDTH, formatInfo->videoWidth);
    OH_AVFormat_SetIntValue(format, OH_MD_KEY_HEIGHT, formatInfo->videoHeight);
    OH_AVFormat_SetDoubleValue(format, OH_MD_KEY_FRAME_RATE, formatInfo->fps);
    OH_AVFormat_SetIntValue(format, OH_MD_KEY_PIXEL_FORMAT, formatInfo->pixelFormat);
    // 配置解码器
    int32_t ret = OH_VideoDecoder_Configure(decoder_, format);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "OH_VideoDecoder_Configure Failed");
        return AV_ERR_UNKNOWN;
    }
    OH_AVFormat_Destroy(format);
    format = nullptr;
    return 0;
}

int32_t VideoDecoder::SetCallback(CodecData *codecData)
{
    // 配置异步回调，调用 OH_VideoDecoder_SetCallback 接口
    int32_t ret = OH_VideoDecoder_RegisterCallback(decoder_, {&CodecData::DataCallback::OnCodecError,
        &CodecData::DataCallback::OnCodecFormatChange,
        &CodecData::DataCallback::OnNeedInputBuffer,
        &CodecData::DataCallback::OnNewOutputBuffer}, codecData);
    if (ret != AV_ERR_OK) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, "VideoDecoder", "SetCallback Failed");
        return ret;
    }
    return ret;
}

const VideoDecoder::DecodeStat &VideoDecoder::Stat() { return stat; }
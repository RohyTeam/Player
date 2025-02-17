/*****************************************************************************
 * ijksdl_aout_android_opensles.c
 *****************************************************************************
 *
 * Copyright (c) 2013 Bilibili
 * copyright (c) 2013 Zhang Rui <bbcallen@gmail.com>
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
 
#include "ijksdl_aout_android_opensles.h"
#include "ohaudio/native_audiorenderer.h"
#include "ohaudio/native_audiostreambuilder.h"
#include "ohaudio/native_audiostream_base.h"
#include "hilog/log.h"
#include "../ijksdl_class.h"
#include "../ijksdl_aout.h"
#include "../ijksdl_audio.h"
#include "../ijksdl_aout_internal.h"

static const int OPENSLES_BUFFERS = 255; /* maximum number of buffers */
static const int OPENSLES_BUFLEN = 10;   /* ms */
static const int GLOBAL_RESMGR = 0xFF00;
static const char *TAG = "[Sample_audio]";
static const int MS_TO_S = 1000;
static const int US_TO_S = 1000000;
static const int NS_TO_US = 1000;
static const int MIN_CALC_INTERVAL_TIME = 1000000; /* us */

static void AoutSetVolume(SDL_Aout *aout, float leftVolume, float rightVolume);

static SDL_Class g_opensles_class = {
    .name = "OpenOhAudio",
};

typedef struct DataFormatPcm {
    Sint32 formatType;
    Sint32 numChannels;
    Sint32 samplesPerSec;
    Sint32 bitsPerSample;
    Sint32 containerSize;
    Sint32 channelMask;
    Sint32 endianness;
    Sint32 samplesRate;
} OHDataFormatPcm;

typedef struct SDL_Aout_Opaque {
    FFPlayer *ffp;
    SDL_Thread * audio_tid;
    SDL_Thread _audio_tid;

    SDL_AudioSpec    spec;
    OHDataFormatPcm  formatPcm;
    int              bytes_per_frame;
    int              milli_per_buffer;
    int              frames_per_buffer;
    int              bytes_per_buffer;

    volatile bool  need_set_volume;
    volatile float left_volume;
    volatile float right_volume;

    volatile bool  abort_request;
    volatile bool  pause_on;
    volatile bool  need_flush;
    volatile bool  is_running;
    
    OH_AudioRenderer *audioRenderer;
    OH_AudioStreamBuilder *rendererBuilder;
    OH_AudioRenderer *audioRendererNormal; // 生成音频播放对象

    volatile int64_t framesWrittenNeedTime; // us
    volatile int64_t lastCalcTime; // us
    volatile int64_t writtenLen;

    uint8_t       * buffer;
    size_t         buffer_capacity;
} SDL_Aout_Opaque;

static void AudioCalcFramesWrittenNeedTime(OH_AudioRenderer *renderer, SDL_Aout_Opaque *opaque)
{
    int64_t nowTime = av_gettime_relative();
    if (nowTime - opaque->lastCalcTime < MIN_CALC_INTERVAL_TIME) {
        return;
    }
    int64_t framePosition = 0;
    int64_t timestamp = 0;
    OH_AudioStream_Result ret = OH_AudioRenderer_GetTimestamp(renderer, CLOCK_MONOTONIC,  &framePosition, &timestamp);
    if (ret != AUDIOSTREAM_SUCCESS) {
        LOGE("OH_AudioRenderer_GetTimestamp failed, ret: %d", ret);
        return;
    }
    nowTime = av_gettime_relative();
    if ((timestamp == 0) || (framePosition == 0)) {
        opaque->framesWrittenNeedTime = 0;
        return;
    }
    int64_t deltaUs = nowTime - timestamp / NS_TO_US;

    int64_t audioPlayedTime = framePosition * US_TO_S / opaque->formatPcm.samplesRate;

    int64_t nowAudioPlayedTime = audioPlayedTime + deltaUs;

    int64_t writtenTime = opaque->writtenLen * US_TO_S / (opaque->formatPcm.samplesRate * opaque->bytes_per_frame);

    opaque->framesWrittenNeedTime = writtenTime - nowAudioPlayedTime;
    opaque->lastCalcTime = nowTime;
}

static int32_t AudioRendererOnWriteData(OH_AudioRenderer *renderer, void *userData, void *buffer, int32_t bufferLen)
{
    SDL_Aout_Opaque *opaque = (SDL_Aout_Opaque*)userData;
    if ((opaque == NULL) || opaque->abort_request || opaque->pause_on) {
        return 0;
    }

    SDL_AudioCallback audioCallback = opaque->spec.callback;
    if (audioCallback == NULL) {
        return 0;
    }
    AudioCalcFramesWrittenNeedTime(renderer, opaque);
    audioCallback(opaque->spec.userdata, (uint8_t *)buffer, bufferLen);
    opaque->writtenLen += bufferLen;
    return 0;
}

static int32_t AudioRendererOnInterrupt(OH_AudioRenderer *renderer, void *userData, OH_AudioInterrupt_ForceType type,
                                        OH_AudioInterrupt_Hint hint)
{
    LOGI("AudioRendererOnInterrupt type:%d, hint:%d", type, hint);
    SDL_Aout_Opaque *opaque = (SDL_Aout_Opaque*)userData;
    if ((opaque == NULL) || (opaque->ffp == NULL)) {
        return -1;
    }
    ffp_notify_msg3(opaque->ffp, FFP_MSG_AUDIO_INTERRUPT, type, hint);
    return 0;
}

static void outputDeviceChangeCallback(OH_AudioRenderer *renderer, void *userData,
                                       OH_AudioStream_DeviceChangeReason reason)
{
    LOGI("outputDeviceChangeCallback reason: %d", reason);
    SDL_Aout_Opaque *opaque = (SDL_Aout_Opaque *)userData;
    if ((opaque == NULL) || (opaque->ffp == NULL)) {
        return;
    }

    ffp_notify_msg2(opaque->ffp, FFP_MSG_AUDIO_DEVICE_CHANGE, reason);
}

static int32_t AudioRendererOnError(OH_AudioRenderer *renderer, void *userData, OH_AudioStream_Result error)
{
    LOGI("AudioRendererOnError result: %d", error);
    SDL_Aout_Opaque *opaque = (SDL_Aout_Opaque*)userData;
    if ((opaque == NULL) || (opaque->ffp == NULL)) {
        return -1;
    }
    if (error != AUDIOSTREAM_SUCCESS) {
        ffp_notify_msg2(opaque->ffp, FFP_MSG_ERROR, error);
    }
    return 0;
}

static double AoutGetLatencySeconds(SDL_Aout *aout)
{
    if ((aout == NULL) || (aout->opaque == NULL)) {
        LOGE("audio->AoutOpenAudio opaque NULL");
        return 0;
    }
    double  latency = (double)aout->opaque->framesWrittenNeedTime / US_TO_S;
    return latency;
}

static int32_t AudioRendererOnStreamEvent(OH_AudioRenderer *renderer, void *userData, OH_AudioStream_Event event)
{
    LOGI("AudioRendererOnStreamEvent, event:%d", event);
    return 0;
}

static void AoutFillFormatPcm(OHDataFormatPcm *formatPcm, const SDL_AudioSpec *desired)
{
    formatPcm->numChannels = desired->channels;
    formatPcm->samplesPerSec = desired->freq * MS_TO_S;
    formatPcm->bitsPerSample = AUDIO_U16LSB;
    formatPcm->containerSize = AUDIO_U16LSB;
    formatPcm->samplesRate = desired->freq;
}

static void AoutSetParams(SDL_Aout *aout, const SDL_AudioSpec *desired)
{
    if ((aout == NULL) || (aout->opaque == NULL)) {
        LOGE("audio->AoutSetParamd opaque NULL");
        return;
    }
    SDL_Aout_Opaque *opaque = aout->opaque;
    // set params and callbacks
    OH_AudioStreamBuilder_SetSamplingRate(opaque->rendererBuilder, desired->freq);
    OH_AudioStreamBuilder_SetChannelCount(opaque->rendererBuilder, desired->channels);
    OH_AudioStreamBuilder_SetSampleFormat(opaque->rendererBuilder, AUDIOSTREAM_SAMPLE_S16LE);
    OH_AudioStreamBuilder_SetEncodingType(opaque->rendererBuilder, AUDIOSTREAM_ENCODING_TYPE_RAW);
    OH_AudioStreamBuilder_SetLatencyMode(opaque->rendererBuilder, AUDIOSTREAM_LATENCY_MODE_NORMAL);
    // 关键参数，仅OHAudio支持，根据音频用途设置，系统会根据此参数实现音频策略自适应
    OH_AudioStreamBuilder_SetRendererInfo(opaque->rendererBuilder, AUDIOSTREAM_USAGE_MOVIE);
}

// 音频渲染器初始化
static int AoutOpenAudio(SDL_Aout *aout, const SDL_AudioSpec *desired, SDL_AudioSpec *obtained)
{
    LOGI("AoutOpenAudio channels:%d, freq:%d, samples:%d, format: %d", desired->channels, desired->freq,
         desired->samples, desired->format);
    if ((aout == NULL) || (aout->opaque == NULL)) {
        LOGE("audio->AoutOpenAudio opaque NULL");
        return -1;
    }
    SDL_Aout_Opaque *opaque = aout->opaque;
    if (opaque->audioRendererNormal != NULL) {
        OH_AudioRenderer_Release(opaque->audioRendererNormal);
        OH_AudioStreamBuilder_Destroy(opaque->rendererBuilder);
        opaque->audioRendererNormal = NULL;
        opaque->rendererBuilder = NULL;
    }

    void *userdata = opaque->spec.userdata;
    OHDataFormatPcm *formatPcm = &opaque->formatPcm;
    opaque->spec = *desired;

    AoutFillFormatPcm(formatPcm, desired);

    // create builder
    OH_AudioStreamBuilder_Create(&opaque->rendererBuilder, AUDIOSTREAM_TYPE_RENDERER);
    // set params and callbacks
    AoutSetParams(aout, desired);
    // 关键参数，仅OHAudio支持，根据音频用途设置，系统会根据此参数实现音频策略自适应
    OH_AudioStreamBuilder_SetRendererInfo(opaque->rendererBuilder, AUDIOSTREAM_USAGE_MOVIE);

    OH_AudioRenderer_Callbacks rendererCallbacks;

    opaque->bytes_per_frame = formatPcm->numChannels * formatPcm->bitsPerSample / AUDIO_U8;
    opaque->milli_per_buffer = OPENSLES_BUFLEN;
    opaque->frames_per_buffer =
        opaque->milli_per_buffer * formatPcm->samplesPerSec / US_TO_S; // samplesPerSec is in milli
    opaque->bytes_per_buffer = opaque->bytes_per_frame * opaque->frames_per_buffer;
    opaque->buffer_capacity = OPENSLES_BUFFERS * opaque->bytes_per_buffer;
    opaque->pause_on = true;
    opaque->abort_request = false;
    opaque->writtenLen = 0;

    rendererCallbacks.OH_AudioRenderer_OnWriteData = AudioRendererOnWriteData; // 看下数据写入OnWriteData
    rendererCallbacks.OH_AudioRenderer_OnStreamEvent = AudioRendererOnStreamEvent;  // 自定义音频流事件函数
    rendererCallbacks.OH_AudioRenderer_OnInterruptEvent = AudioRendererOnInterrupt; // 自定义音频中断事件函数
    rendererCallbacks.OH_AudioRenderer_OnError = AudioRendererOnError; // 自定义异常回调函数

    // 设置输出音频流的回调，在生成音频播放对象时自动注册
    OH_AudioStreamBuilder_SetRendererCallback(opaque->rendererBuilder, rendererCallbacks, opaque);
	// 设置输出音频流设备变更的回调
    OH_AudioStream_Result ret = OH_AudioStreamBuilder_SetRendererOutputDeviceChangeCallback(opaque->rendererBuilder,
        outputDeviceChangeCallback, opaque);
    LOGI("audio->AoutOpenAudio set device change callback ret: %d", ret);

    // 构造播放音频流
    OH_AudioStreamBuilder_GenerateRenderer(opaque->rendererBuilder, &opaque->audioRendererNormal);
    // 设置音频流音量
    AoutSetVolume(aout, aout->opaque->left_volume, aout->opaque->right_volume);
    
    if (obtained != NULL) {
        *obtained = *desired;
        obtained->size = opaque->buffer_capacity;
        obtained->freq = formatPcm->samplesPerSec / MS_TO_S;
    }
    LOGI("audio->aout_open_audio end");
    return opaque->buffer_capacity;
}

static void AoutPauseAudio(SDL_Aout *aout, int pauseOn)
{
    if ((aout == NULL) || (aout->opaque == NULL)) {
        LOGE("audio->AoutPauseAudio opaque NULL");
        return;
    }
    SDL_Aout_Opaque *opaque = aout->opaque;
    if (!opaque->audioRendererNormal) {
        LOGE("audio->AoutPauseAudio audioRendererNormal NULL");
        return;
    }
    opaque->pause_on = pauseOn;
    // 非0表示暂停，0表示取消暂停继续播放
    if (pauseOn != 0) {
        OH_AudioRenderer_Pause(opaque->audioRendererNormal);
    } else {
        aout->opaque->framesWrittenNeedTime = 0;
        aout->opaque->lastCalcTime = av_gettime_relative();
        OH_AudioRenderer_Start(opaque->audioRendererNormal);
    }
    return;
}

static void AudioRendererStop(SDL_Aout *aout)
{
    if ((aout == NULL) || (aout->opaque == NULL)) {
        LOGE("audio->AudioRendererStop opaque NULL");
        return;
    }
    SDL_Aout_Opaque *opaque = aout->opaque;
    if (!opaque->audioRendererNormal) {
        LOGE("audio->AudioRendererStop audioRendererNormal NULL");
        return;
    }
    opaque->abort_request = true;
    OH_AudioRenderer_Stop(opaque->audioRendererNormal);
}

static void AudioRendererFlush(SDL_Aout *aout)
{
    LOGI("audio->AudioRendererFlush");
    if ((aout == NULL) || (aout->opaque == NULL)) {
        LOGE("audio->AudioRendererFlush opaque NULL");
        return;
    }
    SDL_Aout_Opaque *opaque = aout->opaque;
    if (!opaque->audioRendererNormal) {
        LOGE("audio->AudioRendererFlush audioRendererNormal NULL");
        return;
    }
    OH_AudioRenderer_Flush(opaque->audioRendererNormal); // 丢弃已经写入的音频数据
    // 清除音频时延所有参数
    opaque->writtenLen = 0;
    opaque->framesWrittenNeedTime = 0;
    opaque->lastCalcTime = av_gettime_relative();
}

static void AudioRendererRelease(SDL_Aout *aout)
{
    if ((aout == NULL) || (aout->opaque == NULL)) {
        LOGE("audio->AoutSetVolume opaque NULL");
        return;
    }
    SDL_Aout_Opaque *opaque = aout->opaque;
    AudioRendererStop(aout);
    if (opaque->audioRendererNormal) {
        OH_AudioStreamBuilder_Destroy(opaque->rendererBuilder);
        OH_AudioRenderer_Release(opaque->audioRendererNormal);
        opaque->audioRendererNormal = NULL;
    }
    SDL_Aout_FreeInternal(aout);
}

static void AoutSetVolume(SDL_Aout *aout, float leftVolume, float rightVolume)
{
    LOGI("audio->aout_set_volume, leftVolume:%f, rightVolume:%f", leftVolume, rightVolume);
    if ((aout == NULL) || (aout->opaque == NULL)) {
        LOGE("audio->AoutSetVolume opaque NULL");
        return;
    }
    SDL_Aout_Opaque *opaque = aout->opaque;
    opaque->left_volume = leftVolume;
    opaque->right_volume = rightVolume;
    if (opaque->audioRendererNormal != NULL) {
        OH_AudioStream_Result  ret = OH_AudioRenderer_SetVolume(opaque->audioRendererNormal, leftVolume);
        LOGD("audio->aout_set_volume, OH_AudioRenderer_SetVolume ret:%d", ret);
    }
}

SDL_Aout *SDLAoutCreateForOpenSLES(FFPlayer *ffp) // 实现音频播放功能；
{
    LOGI("audio->SDL_AoutAndroid_CreateForOpenSLES");

    SDL_Aout *aout = SDL_Aout_CreateInternal(sizeof(SDL_Aout_Opaque));
    if (aout == NULL) {
        return NULL;
    }

    SDL_Aout_Opaque *opaque = aout->opaque;
    opaque->ffp = ffp;

    aout->free_l = AudioRendererRelease;
    aout->opaque_class = &g_opensles_class;
    aout->open_audio = AoutOpenAudio; // 打开音频

    aout->pause_audio = AoutPauseAudio; // 暂停或播放音频
    aout->flush_audio = AudioRendererFlush;
    aout->close_audio = AudioRendererStop; // 关闭音频
    aout->set_volume = AoutSetVolume;       // 设置音量
    aout->func_get_latency_seconds = AoutGetLatencySeconds;

    return aout;
}

bool SDL_AoutAndroid_IsObjectOfOpenSLES(SDL_Aout * aout)
{
    LOGI("audio->SDL_AoutAndroid_IsObjectOfOpenSLES");
    if (aout == NULL) {
        return false;
    }
    return aout->opaque_class == &g_opensles_class;
}
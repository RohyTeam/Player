/*
 * ijkplayer_record.h
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

#ifndef IJKPLAYER_RECORD_H
#define IJKPLAYER_RECORD_H

#include <pthread.h>
#include "unistd.h"
#ifdef __cplusplus
extern "C" {
#endif
#include "libavcodec/avcodec.h"
#include "libavutil/avutil.h"
#include "libswscale/swscale.h"
#include "libavutil/imgutils.h"
#include "libswresample/swresample.h"
#include "libavutil/timestamp.h"
#include "libavutil/mathematics.h"
#include "libavutil/opt.h"
#include "libavutil/avassert.h"
#include "libavformat/avformat.h"
#ifdef __cplusplus
}
#endif
#define STREAM_DURATION   10.0
#define STREAM_FRAME_RATE 25
#define STREAM_PIX_FMT    AV_PIX_FMT_YUV420P
#define SCALE_FLAGS SWS_BICUBIC
#define AVFMT_RAWPICTURE    0x0020

#define OHOS_FRAME_TYPE_VIDEO  0
#define OHOS_FRAME_TYPE_AUDIO 1
#define OHOS_MAX_DECODE_FRAME_SIZE 9999999
#define OHOS_RECORD_STATUS_OFF 0
#define OHOS_RECORD_STATUS_ON 1
#define OHOS_RECORD_CALLBACK_STATUS_SUCCESS 1
#define OHOS_RECORD_CALLBACK_STATUS_FAILED 0
#define FRAME_DATA_NUM_1 1
#define FRAME_DATA_NUM_2 2
#define FRAME_DATA_NUM_3 3
#define DATA_NUM_0 0
#define DATA_NUM_1 1
#define DATA_NUM_2 2
#define DATA_NUM_3 3
#define DATA_NUM_32 32
#define DATA_NUM_50 50
#define DATA_NUM_12 12
#define DATA_NUM_25 25
#define DATA_NUM_10000 10000
#define DATA_NUM_48000 48000
#define DATA_NUM_64000 64000
#define DATA_NUM_64000 64000
#define VIDEO_BIT_RATE (2028 * 1024)
#define SLEEP_TIME 1000
#define SLEEP_TIME_100 100
#define SLEEP_TIME_2 2
#define SLEEP_TIME_5 5
#define DATA_NUM_110 110.0
#define OHOS_CALLBACK_RESULT_STATUS_SUCCESS 1
#define OHOS_CALLBACK_RESULT_STATUS_FAILED 0

typedef struct OutputStream {
    AVStream *st;
    int64_t next_pts;
    int samples_count;
    AVFrame *frame;
    AVFrame *tmp_frame;
    float t, tincr, tincr2;
    struct SwsContext *sws_ctx;
    struct SwrContext *swr_ctx;
} OutputStream;

typedef struct InputSourceInfo {
    int width, height;
}InputSourceInfo;

typedef struct RecordFrameData {
    uint8_t* data0;
    uint8_t* data1;
    uint8_t* data2;
    int lineSize0;
    int lineSize1;
    int lineSize2;
    int dataNum;
    int frameType;
    int nb_samples;
    uint64_t channel_layout;
    int channels;
    int format;
    int writeFileStatus;
}RecordFrameData;

typedef struct RecordWriteData {
    OutputStream video_st;
    OutputStream audio_st;
    AVFormatContext *oc;
    AVOutputFormat *fmt;
    AVCodec *audio_codec, *video_codec;
    char *recordFilePath;
    InputSourceInfo srcFormat;
    RecordFrameData *recordFramesQueue;
    int rindex;
    int windex;
    int isInRecord;
    pthread_t recThreadid;
    int sampleRate;
}RecordWriteData;

int AddStream(OutputStream *ost, AVFormatContext *oc,
              AVCodec **codec, enum AVCodecID codec_id,
              InputSourceInfo inputSrcInfo, int sampleRate, int frameRate);
int OpenVideo(AVFormatContext *oc, AVCodec *codec, OutputStream *ost, AVDictionary *opt_arg);
int OpenAudio(AVFormatContext *oc, AVCodec *codec, OutputStream *ost, AVDictionary *opt_arg);
AVFrame *RecordAllocPicture(enum AVPixelFormat pix_fmt, int width, int height);
AVFrame *AllocAudioFrame(enum AVSampleFormat sample_fmt,
                         uint64_t channel_layout,
                         int sample_rate, int nb_samples);
int WriteVideoFrame(AVFormatContext* oc, OutputStream* ost, AVFrame* curFr);
int WriteFrame(AVFormatContext *fmtCtx, const AVRational *time_base, AVStream *st, AVPacket *pkt);
void LogPacket(const AVFormatContext *fmtCtx, const AVPacket *pkt);
int WriteAudioFrame(AVFormatContext* oc, OutputStream* ost, AVFrame* curFr);
void CloseStream(AVFormatContext *oc, OutputStream *ost);
void FreeRecordFrames(RecordWriteData* recData);
#ifdef __cplusplus
extern "C" {
#endif
    int WriteRecordFile(void *recordData);
    void UpdateRecordStatus(void* ffp, int status);
    void UpdateRecordResult(void *ffp, int result);
    int FindRecordResult(void *ffp);
    void SaveCurrentFramePicture(AVFrame *frame, const char *saveFilePath);
#ifdef __cplusplus
}
#endif
#endif //IJKPLAYER_RECORD_H

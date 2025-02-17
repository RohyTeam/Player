/*
 * ijkplayer_record.c
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

#include "ijkplayer_record.h"
#include <unordered_map>
#include "ijkplayer_internal.h"
static std::unordered_map<void *, int> ijkplayerRecordStatusMap;
static std::unordered_map<void *, int> ijkplayerRecordResultMap;

struct VideoAudioAvCodec {
    int haveVideo = 0;
    int haveAudio = 0;
    int result = 0;
};

void handleCodecAudioStream(AVCodecContext *c, OutputStream *ost, AVCodec **codec, int sample_rate)
{
    int i;
    c->sample_fmt = (*codec)->sample_fmts ? (*codec)->sample_fmts[0] : AV_SAMPLE_FMT_FLTP;
    c->bit_rate = DATA_NUM_64000;
    if (sample_rate == 0) {
        sample_rate = DATA_NUM_48000;
    }
    c->sample_rate = sample_rate;
    if ((*codec)->supported_samplerates) {
        c->sample_rate = (*codec)->supported_samplerates[0];
        for (i = 0; (*codec)->supported_samplerates[i]; i++) {
            if ((*codec)->supported_samplerates[i] == sample_rate)
                c->sample_rate = sample_rate;
        }
    }
    c->channels = av_get_channel_layout_nb_channels(c->channel_layout);
    c->channel_layout = AV_CH_LAYOUT_STEREO;
    if ((*codec)->channel_layouts) {
        c->channel_layout = (*codec)->channel_layouts[0];
        for (i = 0; (*codec)->channel_layouts[i]; i++) {
            if ((*codec)->channel_layouts[i] == AV_CH_LAYOUT_STEREO)
                c->channel_layout = AV_CH_LAYOUT_STEREO;
        }
    }
    c->channels = av_get_channel_layout_nb_channels(c->channel_layout);
    ost->st->time_base = (AVRational){1, c->sample_rate};
}

void handleCodecVideoStream(AVCodecContext *c, OutputStream *ost, enum AVCodecID codec_id,
                            InputSourceInfo inpSrcInfo, int frameRate)
{
    c->codec_id = codec_id;
    c->bit_rate = VIDEO_BIT_RATE;
    c->width = inpSrcInfo.width;
    c->height = inpSrcInfo.height;
    ost->st->time_base = (AVRational){1, frameRate};
    c->time_base = ost->st->time_base;
    c->gop_size = DATA_NUM_12;
    c->pix_fmt = STREAM_PIX_FMT;
    if (c->codec_id == AV_CODEC_ID_MPEG2VIDEO) {
        c->max_b_frames = DATA_NUM_2;
    }
    if (c->codec_id == AV_CODEC_ID_MPEG1VIDEO) {
        c->mb_decision = DATA_NUM_2;
    }
}

int AddStream(OutputStream *ost, AVFormatContext *oc, AVCodec **codec, enum AVCodecID codec_id,
              InputSourceInfo inpSrcInfo, int sampleRate, int frameRate)
{
    AVCodecContext *c;
    int i;
    if (codec_id == AV_CODEC_ID_MPEG4) {
        codec_id = AV_CODEC_ID_H264;
    }
    *codec = avcodec_find_encoder(codec_id);
    if (!(*codec)) {
        LOGE("not find encoder %s", avcodec_get_name(codec_id));
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    ost->st = avformat_new_stream(oc, *codec);
    if (!ost->st) {
        LOGE("Could not allocate stream");
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    ost->st->id = oc->nb_streams - 1;
    c = ost->st->codec;
    switch ((*codec)->type) {
        case AVMEDIA_TYPE_AUDIO:
            handleCodecAudioStream(c, ost, codec, sampleRate);
            break;
        case AVMEDIA_TYPE_VIDEO:
            handleCodecVideoStream(c, ost, codec_id, inpSrcInfo, frameRate);
            break;
        default:
            break;
    }
    if (oc->oformat->flags & AVFMT_GLOBALHEADER) {
        c->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
    }
    return OHOS_RECORD_CALLBACK_STATUS_SUCCESS;
}

int OpenVideo(AVFormatContext *oc, AVCodec *codec, OutputStream *ost, AVDictionary *opt_arg)
{
    int ret;
    AVCodecContext *c = ost->st->codec;
    AVDictionary *opt = NULL;
    av_dict_copy(&opt, opt_arg, 0);
    ret = avcodec_open2(c, codec, &opt);
    av_dict_free(&opt);
    if (ret < 0) {
        LOGE("Could not open video codec: %s", av_err2str(ret));
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    ost->frame = RecordAllocPicture(c->pix_fmt, c->width, c->height);
    if (!ost->frame) {
        LOGE("Could not allocate video frame");
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    ost->tmp_frame = NULL;
    if (c->pix_fmt != AV_PIX_FMT_YUV420P) {
        ost->tmp_frame = RecordAllocPicture(AV_PIX_FMT_YUV420P, c->width, c->height);
        if (!ost->tmp_frame) {
            LOGE("Could not allocate temporary picture");
            return OHOS_RECORD_CALLBACK_STATUS_FAILED;
        }
    }
    return OHOS_RECORD_CALLBACK_STATUS_SUCCESS;
}

int OpenAudio(AVFormatContext *oc, AVCodec *codec, OutputStream *ost, AVDictionary *opt_arg)
{
    AVCodecContext *c;
    int nb_samples;
    int ret;
    AVDictionary *opt = NULL;
    c = ost->st->codec;
    av_dict_copy(&opt, opt_arg, 0);
    ret = avcodec_open2(c, codec, &opt);
    av_dict_free(&opt);
    if (ret < 0) {
        LOGE("Could not open audio codec: %s", av_err2str(ret));
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    ost->t = 0;
    ost->tincr = DATA_NUM_2 * M_PI * DATA_NUM_110 / c->sample_rate;
    ost->tincr2 = DATA_NUM_2 * M_PI * DATA_NUM_110 / c->sample_rate / c->sample_rate;
    if (c->codec->capabilities & AV_CODEC_CAP_VARIABLE_FRAME_SIZE) {
        nb_samples = DATA_NUM_10000;
    } else {
        nb_samples = c->frame_size;
    }
    ost->frame = AllocAudioFrame(c->sample_fmt, c->channel_layout, c->sample_rate, nb_samples);
    ost->tmp_frame = AllocAudioFrame(AV_SAMPLE_FMT_FLTP, c->channel_layout, c->sample_rate, nb_samples);
    ost->swr_ctx = swr_alloc();
    if (!ost->swr_ctx) {
        LOGE("Could not allocate resampler context");
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    av_opt_set_int(ost->swr_ctx, "in_channel_count", c->channels, 0);
    av_opt_set_int(ost->swr_ctx, "in_sample_rate", c->sample_rate, 0);
    av_opt_set_sample_fmt(ost->swr_ctx, "in_sample_fmt", AV_SAMPLE_FMT_S16, 0);
    av_opt_set_int(ost->swr_ctx, "out_channel_count", c->channels, 0);
    av_opt_set_int(ost->swr_ctx, "out_sample_rate", c->sample_rate, 0);
    av_opt_set_sample_fmt(ost->swr_ctx, "out_sample_fmt", AV_SAMPLE_FMT_FLTP, 0);
    if ((ret = swr_init(ost->swr_ctx)) < 0) {
        LOGE("Failed to initialize the resampling context");
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    return OHOS_RECORD_CALLBACK_STATUS_SUCCESS;
}

AVFrame *RecordAllocPicture(enum AVPixelFormat pix_fmt, int width, int height)
{
    AVFrame *picture;
    int ret;
    picture = av_frame_alloc();
    if (!picture) {
        return nullptr;
    }
    picture->format = pix_fmt;
    picture->width = width;
    picture->height = height;
    ret = av_frame_get_buffer(picture, DATA_NUM_32);
    if (ret < 0) {
        LOGE("Could not allocate frame data.");
        return nullptr;
    }
    return picture;
}

AVFrame *AllocAudioFrame(enum AVSampleFormat sample_fmt, uint64_t channel_layout, int sample_rate, int nb_samples)
{
    AVFrame *frame = av_frame_alloc();
    int ret;
    if (!frame) {
        LOGE("Error allocating an audio frame");
        return nullptr;
    }
    frame->format = sample_fmt;
    frame->channel_layout = channel_layout;
    frame->sample_rate = sample_rate;
    frame->nb_samples = nb_samples;
    if (nb_samples) {
        ret = av_frame_get_buffer(frame, 0);
        if (ret < 0) {
            LOGE("Error allocating an audio buffer");
            return nullptr;
        }
    }
    return frame;
}


int WriteVideoFrame(AVFormatContext *oc, OutputStream *ost, AVFrame *curFr)
{
    int ret;
    AVCodecContext *c;
    AVFrame *frame;
    int gotPacket = 0;
    c = ost->st->codec;
    frame = curFr;
    if (oc->oformat->flags & AVFMT_RAWPICTURE) {
        AVPacket pkt;
        av_init_packet(&pkt);
        if (!frame) {
            LOGE("oc->oformat->flags frame check null");
            return OHOS_RECORD_CALLBACK_STATUS_FAILED;
        }
        pkt.flags |= AV_PKT_FLAG_KEY;
        pkt.stream_index = ost->st->index;
        pkt.data = (uint8_t *)frame;
        pkt.size = sizeof(AVPicture);
        pkt.pts = pkt.dts = frame->pts;
        av_packet_rescale_ts(&pkt, c->time_base, ost->st->time_base);
        ret = av_interleaved_write_frame(oc, &pkt);
        av_free_packet(&pkt);
    } else {
        AVPacket pkt = {0};
        av_init_packet(&pkt);
        ret = avcodec_encode_video2(c, &pkt, frame, &gotPacket);
        if (ret < 0) {
            LOGE("Error encoding video frame: %s", av_err2str(ret));
            return OHOS_RECORD_CALLBACK_STATUS_FAILED;
        }
        if (gotPacket) {
            ret = WriteFrame(oc, &c->time_base, ost->st, &pkt);
        } else {
            ret = OHOS_RECORD_CALLBACK_STATUS_FAILED;
        }
        av_free_packet(&pkt);
    }
    if (ret < 0) {
        LOGE("Error while writing video frame: %s", av_err2str(ret));
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    return (frame || gotPacket) ? OHOS_RECORD_CALLBACK_STATUS_SUCCESS : OHOS_RECORD_CALLBACK_STATUS_FAILED;
}


int WriteFrame(AVFormatContext *fmtCtx, const AVRational *time_base, AVStream *st, AVPacket *pkt)
{
    av_packet_rescale_ts(pkt, *time_base, st->time_base);
    pkt->stream_index = st->index;
    return av_interleaved_write_frame(fmtCtx, pkt);
}

int WriteAudioFrame(AVFormatContext *oc, OutputStream *ost, AVFrame *curFr)
{
    AVCodecContext *c;
    AVPacket pkt = {0};
    AVFrame *frame;
    int ret;
    int gotPacket;
    int dst_nb_samples;
    av_init_packet(&pkt);
    c = ost->st->codec;
    frame = curFr;
    if (frame) {
        if (frame->format == AV_SAMPLE_FMT_S16) {
            frame->pts = ost->next_pts;
            dst_nb_samples = av_rescale_rnd(swr_get_delay(ost->swr_ctx, c->sample_rate) + frame->nb_samples,
                                            c->sample_rate, c->sample_rate, AV_ROUND_UP);
            av_assert0(dst_nb_samples == frame->nb_samples);
            ret = av_frame_make_writable(ost->frame);
            if (ret < 0) {
                return OHOS_RECORD_CALLBACK_STATUS_FAILED;
            }
            ret = swr_convert(ost->swr_ctx, ost->frame->data, dst_nb_samples, (const uint8_t **)frame->data,
                              frame->nb_samples);
            if (ret < 0) {
                LOGE("Error while converting");
                return OHOS_RECORD_CALLBACK_STATUS_FAILED;
            }
            frame = ost->frame;
            ost->next_pts += dst_nb_samples;
        } else {
            dst_nb_samples = curFr->nb_samples;
        }
        frame->pts = av_rescale_q(ost->samples_count, (AVRational){1, c->sample_rate}, c->time_base);
        ost->samples_count += dst_nb_samples;
    }
    ret = avcodec_encode_audio2(c, &pkt, frame, &gotPacket);
    if (ret < 0) {
        LOGE("Error encoding audio frame: %s", av_err2str(ret));
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    if (gotPacket) {
        ret = WriteFrame(oc, &c->time_base, ost->st, &pkt);
        if (ret < 0) {
            LOGE("Error while writing audio frame: %s", av_err2str(ret));
            return OHOS_RECORD_CALLBACK_STATUS_FAILED;
        }
    }
    return (frame || gotPacket) ? OHOS_RECORD_CALLBACK_STATUS_SUCCESS : OHOS_RECORD_CALLBACK_STATUS_FAILED;
}

void CloseStream(AVFormatContext *oc, OutputStream *ost)
{
    avcodec_close(ost->st->codec);
    av_frame_free(&ost->frame);
    av_frame_free(&ost->tmp_frame);
    sws_freeContext(ost->sws_ctx);
    swr_free(&ost->swr_ctx);
}

int GetRecordStatus(FFPlayer *ffp)
{
    if (!ffp) {
        LOGE("getRecordStatus ffp null");
        return OHOS_RECORD_STATUS_OFF;
    }
    auto it = ijkplayerRecordStatusMap.find(ffp);
    if (it != ijkplayerRecordStatusMap.end()) {
        return it->second;
    }
    return OHOS_RECORD_STATUS_OFF;
}


VideoAudioAvCodec VideoAudioStreamAndAvcodecOpen(RecordWriteData *recordWriteData, FFPlayer *mFFPlayer,
                                                 AVDictionary *opt)
{
    int haveVideo = 0, haveAudio = 0;
    VideoAudioAvCodec vaAvcodec;
    AVOutputFormat *fmt = recordWriteData->oc->oformat;
    int frameRate = av_q2d(mFFPlayer->is->video_st->avg_frame_rate);
    if (fmt->video_codec != AV_CODEC_ID_NONE) {
        int addStreamResult =
            AddStream(&(recordWriteData->video_st), recordWriteData->oc, &(recordWriteData->video_codec),
                      fmt->video_codec, recordWriteData->srcFormat, recordWriteData->sampleRate, frameRate);
        if (addStreamResult == 0) {
            UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_FAILED);
            vaAvcodec.result = OHOS_RECORD_CALLBACK_STATUS_FAILED;
            return vaAvcodec;
        }
        haveVideo = 1;
    }
    if (fmt->audio_codec != AV_CODEC_ID_NONE) {
        int addStreamResult =
            AddStream(&(recordWriteData->audio_st), recordWriteData->oc, &recordWriteData->audio_codec,
                      fmt->audio_codec, recordWriteData->srcFormat, recordWriteData->sampleRate, frameRate);
        if (addStreamResult == 0) {
            UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_FAILED);
            vaAvcodec.result = OHOS_RECORD_CALLBACK_STATUS_FAILED;
            return vaAvcodec;
        }
        haveAudio = 1;
    }
    if (haveVideo) {
        int openVideoResult =
            OpenVideo(recordWriteData->oc, recordWriteData->video_codec, &recordWriteData->video_st, opt);
        if (openVideoResult == 0) {
            UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_FAILED);
            vaAvcodec.result = OHOS_RECORD_CALLBACK_STATUS_FAILED;
            return vaAvcodec;
        }
    }
    if (haveAudio) {
        int openAudioResult =
            OpenAudio(recordWriteData->oc, recordWriteData->audio_codec, &recordWriteData->audio_st, opt);
        if (openAudioResult == 0) {
            UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_FAILED);
            vaAvcodec.result = OHOS_RECORD_CALLBACK_STATUS_FAILED;
            return vaAvcodec;
        }
    }
    vaAvcodec.haveAudio = haveVideo;
    vaAvcodec.haveAudio = haveAudio;
    vaAvcodec.result = OHOS_RECORD_CALLBACK_STATUS_SUCCESS;
    return vaAvcodec;
}

void WriteVideoFrameData(AVFormatContext *oc, RecordFrameData frData, SwsContext *swsContext,
                         InputSourceInfo inSrcInfo, RecordWriteData *recordWriteData)
{
    uint8_t *srcSlice[3];
    srcSlice[DATA_NUM_0] = frData.data0;
    srcSlice[DATA_NUM_1] = frData.data1;
    srcSlice[DATA_NUM_2] = frData.data2;
    int srcLineSize[3];
    srcLineSize[DATA_NUM_0] = frData.lineSize0;
    srcLineSize[DATA_NUM_1] = frData.lineSize1;
    srcLineSize[DATA_NUM_2] = frData.lineSize2;
    int dstLineSize[3];
    dstLineSize[DATA_NUM_0] = inSrcInfo.width;
    dstLineSize[DATA_NUM_1] = inSrcInfo.width / DATA_NUM_2;
    dstLineSize[DATA_NUM_2] = inSrcInfo.width / DATA_NUM_2;
    sws_scale(swsContext, (const uint8_t *const *)srcSlice, srcLineSize, 0, inSrcInfo.height,
              recordWriteData->video_st.frame->data, recordWriteData->video_st.frame->linesize);
    recordWriteData->video_st.frame->pts = recordWriteData->video_st.next_pts++;
    WriteVideoFrame(oc, &recordWriteData->video_st, recordWriteData->video_st.frame);
}

void FreeFramesQueueIndexFrame(RecordWriteData *recordWriteData, int index)
{
    if (recordWriteData->recordFramesQueue[index].dataNum == DATA_NUM_3 ||
        recordWriteData->recordFramesQueue[index].dataNum == DATA_NUM_2) {
        if (recordWriteData->recordFramesQueue[index].data0) {
            free(recordWriteData->recordFramesQueue[index].data0);
            recordWriteData->recordFramesQueue[index].data0 = NULL;
        }
        if (recordWriteData->recordFramesQueue[index].data1) {
            free(recordWriteData->recordFramesQueue[index].data1);
            recordWriteData->recordFramesQueue[index].data1 = NULL;
        }
    }
    if (recordWriteData->recordFramesQueue[index].dataNum == DATA_NUM_3) {
        if (recordWriteData->recordFramesQueue[index].data2) {
            free(recordWriteData->recordFramesQueue[index].data2);
            recordWriteData->recordFramesQueue[index].data2 = NULL;
        }
    }
}

void WriteRecordFrameData(AVFormatContext *oc, RecordWriteData *recordWriteData, OutputStream *audioStPtr, int index,
                          SwsContext *swsContext, InputSourceInfo inSrcInfo)
{
    RecordFrameData frData = recordWriteData->recordFramesQueue[index];
    if (frData.writeFileStatus != 0) {
        return;
    }
    if (frData.frameType == OHOS_FRAME_TYPE_VIDEO) {
        WriteVideoFrameData(oc, frData, swsContext, inSrcInfo, recordWriteData);
        FreeFramesQueueIndexFrame(recordWriteData, index);
    } else {
        if (frData.format == AV_SAMPLE_FMT_FLTP) {
            AVFrame *tmpFr = audioStPtr->tmp_frame;
            tmpFr->data[DATA_NUM_0] = (uint8_t *)av_malloc(frData.lineSize0);
            tmpFr->data[DATA_NUM_1] = (uint8_t *)av_malloc(frData.lineSize1);
            if (frData.data0 && frData.data1) {
                memcpy(tmpFr->data[DATA_NUM_0], frData.data0, frData.lineSize0);
                memcpy(tmpFr->data[DATA_NUM_1], frData.data1, frData.lineSize1);
                tmpFr->nb_samples = frData.nb_samples;
                tmpFr->channels = frData.channels;
                tmpFr->channel_layout = frData.channel_layout;
                tmpFr->pts = audioStPtr->next_pts;
                audioStPtr->next_pts += tmpFr->nb_samples;
                tmpFr->format = frData.format;
                WriteAudioFrame(oc, audioStPtr, tmpFr);
                free(tmpFr->data[DATA_NUM_0]);
                tmpFr->data[DATA_NUM_0] = NULL;
                free(tmpFr->data[DATA_NUM_1]);
                tmpFr->data[DATA_NUM_1] = NULL;
            }
        } else if (frData.format == AV_SAMPLE_FMT_S16) {
            AVFrame *tmpFr = audioStPtr->tmp_frame;
            tmpFr->nb_samples = frData.nb_samples;
            tmpFr->channels = frData.channels;
            tmpFr->channel_layout = frData.channel_layout;
            tmpFr->linesize[DATA_NUM_0] = frData.lineSize0;
            tmpFr->data[DATA_NUM_0] = (uint8_t *)av_malloc(frData.lineSize0);
            if (frData.data0) {
                memcpy(tmpFr->data[DATA_NUM_0], frData.data0, frData.lineSize0);
                tmpFr->format = frData.format;
                WriteAudioFrame(oc, audioStPtr, tmpFr);
                free(tmpFr->data[DATA_NUM_0]);
                tmpFr->data[DATA_NUM_0] = NULL;
            }
        }
        FreeFramesQueueIndexFrame(recordWriteData, index);
    }
    recordWriteData->recordFramesQueue[index].writeFileStatus = DATA_NUM_1;
}

void StartEncoderWrite(AVFormatContext *oc, RecordWriteData *recordWriteData, FFPlayer *mFFPlayer,
                       OutputStream *audioStPtr)
{
    InputSourceInfo inSrcInfo = recordWriteData->srcFormat;
    struct SwsContext *swsContext =
        sws_getContext(inSrcInfo.width, inSrcInfo.height, AV_PIX_FMT_YUV420P, inSrcInfo.width, inSrcInfo.height,
                       AV_PIX_FMT_YUV420P, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    while (true) {
        recordWriteData = &mFFPlayer->record_write_data;
        int totalFrameIndex = recordWriteData->windex;
        for (int i = 0; i < totalFrameIndex; i++) {
            usleep(SLEEP_TIME_100);
            WriteRecordFrameData(oc, recordWriteData, audioStPtr, i, swsContext, inSrcInfo);
        }
        if (GetRecordStatus(mFFPlayer) != OHOS_RECORD_STATUS_ON) {
            break;
        }
    }
}

void ReleaseResources(AVFormatContext *oc, RecordWriteData *recordWriteData, AVOutputFormat *fmt,
                      int haveVideo, int haveAudio, OutputStream *videoStPtr, OutputStream *audioStPtr)
{
        FreeRecordFrames(recordWriteData);
        av_write_trailer(oc);
        if (haveVideo) {
        CloseStream(oc, videoStPtr);
        }
        if (haveAudio) {
        CloseStream(oc, audioStPtr);
        }
        if (!(fmt->flags & AVFMT_NOFILE)) {
        avio_closep(&oc->pb);
        }
        avformat_free_context(oc);
}

int CheckAVFormatContext(AVFormatContext *oc, FFPlayer *mFFPlayer, const char *fileName)
{
    if (!oc) {
        avformat_alloc_output_context2(&oc, NULL, "mp4", fileName);
    }
    if (!oc) {
        LOGE("oc null");
        UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_FAILED);
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    return OHOS_RECORD_CALLBACK_STATUS_SUCCESS;
}

RecordWriteData* WaitCacheVideoFrames(FFPlayer *mFFPlayer)
{
        RecordWriteData *recordWriteData;
        while (true) {
            recordWriteData = &mFFPlayer->record_write_data;
            if ((&mFFPlayer->record_write_data)->windex > DATA_NUM_50
                || GetRecordStatus(mFFPlayer) != OHOS_RECORD_STATUS_ON) {
                break;
            }
            usleep(SLEEP_TIME);
        }
        return recordWriteData;
}

int WriteRecordFile(void *recordData)
{
    FFPlayer *mFFPlayer = (FFPlayer *)(recordData);
    RecordWriteData *recordWriteData = &mFFPlayer->record_write_data;
    const char *fileName = recordWriteData->recordFilePath;
    recordWriteData = WaitCacheVideoFrames(mFFPlayer);
    if (recordWriteData->windex == 0) {
        LOGE("Error check no frame");
        UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_FAILED);
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    AVOutputFormat *fmt;
    OutputStream *videoStPtr;
    OutputStream *audioStPtr;
    int ret;
    AVDictionary *opt = NULL;
    av_dict_set(&opt, "preset", "veryfast", 0);
    av_dict_set(&opt, "tune", "zerolatency", 0);
    avformat_alloc_output_context2(&(recordWriteData->oc), NULL, NULL, fileName);
    int checkResult = CheckAVFormatContext(recordWriteData->oc, mFFPlayer, fileName);
    if (!checkResult) {
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    auto vaAvcodec = VideoAudioStreamAndAvcodecOpen(recordWriteData, mFFPlayer, opt);
    if (!vaAvcodec.result) {
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    videoStPtr = &recordWriteData->video_st;
    audioStPtr = &recordWriteData->audio_st;
    av_dump_format(recordWriteData->oc, 0, fileName, 1);
    if (!(recordWriteData->oc->oformat->flags & AVFMT_NOFILE)) {
        ret = avio_open(&recordWriteData->oc->pb, fileName, AVIO_FLAG_WRITE);
        if (ret < 0) {
            LOGE("Could not open %s", fileName);
            UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_FAILED);
            return OHOS_RECORD_CALLBACK_STATUS_FAILED;
        }
    }
    ret = avformat_write_header(recordWriteData->oc, &opt);
    if (ret < 0) {
        LOGE("Error occurred when opening output file %s", av_err2str(ret));
        UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_FAILED);
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    StartEncoderWrite(recordWriteData->oc, recordWriteData, mFFPlayer, audioStPtr);
    ReleaseResources(recordWriteData->oc, recordWriteData, recordWriteData->oc->oformat,
                     vaAvcodec.haveVideo, vaAvcodec.haveAudio, videoStPtr, audioStPtr);
    UpdateRecordResult(mFFPlayer, OHOS_RECORD_CALLBACK_STATUS_SUCCESS);
    return OHOS_RECORD_CALLBACK_STATUS_SUCCESS;
}

void FreeRecordFrames(RecordWriteData *recData)
{
    recData->windex = DATA_NUM_0;
    free(recData->recordFramesQueue);
    recData->recordFramesQueue = nullptr;
}

void UpdateRecordStatus(void *ffp, int status)
{
        ijkplayerRecordStatusMap[ffp] = status;
}

void UpdateRecordResult(void *ffp, int result)
{
        ijkplayerRecordResultMap[ffp] = result;
}

int FindRecordResult(void *ffp)
{
    if (!ffp) {
        LOGE("findRecordResult ffp null");
        return OHOS_RECORD_CALLBACK_STATUS_FAILED;
    }
    sleep(SLEEP_TIME_2);
    auto it = ijkplayerRecordResultMap.find(ffp);
    if (it != ijkplayerRecordResultMap.end()) {
        return it->second;
    } else {
        sleep(SLEEP_TIME_5);
        auto it = ijkplayerRecordResultMap.find(ffp);
        if (it != ijkplayerRecordResultMap.end()) {
            return it->second;
        }
    }
    LOGE("findRecordResult not find");
    return OHOS_RECORD_CALLBACK_STATUS_FAILED;
}

void HandleEncodeWritePicture(AVCodecContext *pCodecCtx, AVStream *video_st, AVFormatContext *pFormatCtx,
                              AVFrame *frame)
{
    AVPacket pkt;
    AVCodec *pCodec;
    int y_size;
    int ret = 0;
    int got_picture = 0;
    pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
    if (!pCodec) {
        avcodec_close(video_st->codec);
        avio_close(pFormatCtx->pb);
        avformat_free_context(pFormatCtx);
        return;
    }
    if (avcodec_open2(pCodecCtx, pCodec, NULL) < 0) {
        avcodec_close(video_st->codec);
        avio_close(pFormatCtx->pb);
        avformat_free_context(pFormatCtx);
        return;
    }
    avformat_write_header(pFormatCtx, NULL);
    y_size = pCodecCtx->width * pCodecCtx->height;
    av_new_packet(&pkt, y_size * DATA_NUM_3);
    ret = avcodec_encode_video2(pCodecCtx, &pkt, frame, &got_picture);
    if (ret < 0) {
        avcodec_close(video_st->codec);
        avio_close(pFormatCtx->pb);
        avformat_free_context(pFormatCtx);
        return;
    }
    if (got_picture == 1) {
        pkt.stream_index = video_st->index;
        ret = av_write_frame(pFormatCtx, &pkt);
    }
    av_free_packet(&pkt);
    av_write_trailer(pFormatCtx);
    if (video_st) {
        avcodec_close(video_st->codec);
    }
    avio_close(pFormatCtx->pb);
    avformat_free_context(pFormatCtx);
}

void SaveCurrentFramePicture(AVFrame *frame, const char *saveFilePath)
{
    AVFormatContext *pFormatCtx;
    AVOutputFormat *fmt;
    AVStream *video_st;
    AVCodecContext *pCodecCtx;
    pFormatCtx = avformat_alloc_context();
    fmt = av_guess_format("mjpeg", NULL, NULL);
    pFormatCtx->oformat = fmt;
    if (avio_open(&pFormatCtx->pb, saveFilePath, AVIO_FLAG_READ_WRITE) < 0) {
        avformat_free_context(pFormatCtx);
        return;
    }
    video_st = avformat_new_stream(pFormatCtx, 0);
    if (video_st == NULL) {
        avio_close(pFormatCtx->pb);
        avformat_free_context(pFormatCtx);
        return;
    }
    pCodecCtx = video_st->codec;
    pCodecCtx->codec_id = fmt->video_codec;
    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    pCodecCtx->pix_fmt = AV_PIX_FMT_YUVJ420P;
    pCodecCtx->width = frame->width;
    pCodecCtx->height = frame->height;
    pCodecCtx->time_base.num = DATA_NUM_1;
    pCodecCtx->time_base.den = DATA_NUM_25;
    av_dump_format(pFormatCtx, 0, saveFilePath, 1);
    HandleEncodeWritePicture(pCodecCtx, video_st, pFormatCtx, frame);
}

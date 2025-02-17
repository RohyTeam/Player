/*
 * ffpipenode_ohos_mediacodec_vdec.cpp
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

#include "ffpipenode_ohos_mediacodec_vdec.h"

#include <chrono>
#include <unistd.h>
#include "libswscale/swscale.h"
#include "ohos_video_decoder_data.h"
#include "ohos_video_decoder.h"

static const int NS_TO_US = 1000;
static const int MILLISECOND = 7;

class IJKFF_Pipenode_Opaque {
public:
    IJKFF_Pipeline *pipeline;
    FormatInfo formatInfoEntry;
    CodecData codecData;
    VideoDecoder decoder;
    FFPlayer *ffp;
    AVCodecParameters *codecpar;
    AVPacket *pkt;
    SDL_Vout *weakVout;
    const AVBitStreamFilter *aVBitStreamFilter = {nullptr};
    AVBSFContext *avbsfContext {nullptr};
    std::atomic_int64_t frameCount {0};
    void DecoderInput(AVPacket pkt);
    void DecoderOutput(AVFrame *frame);
};

static void func_destroy(IJKFF_Pipenode *node)
{
    IJKFF_Pipenode_Opaque *opaque = static_cast<IJKFF_Pipenode_Opaque *>(node->opaque);
    opaque->decoder.Release();
}
void IJKFF_Pipenode_Opaque::DecoderInput(AVPacket pkt)
{
    int32_t ret = 0;
    int inputTime = 30;
    CodecBufferInfo codecBufferInfo;
    codecBufferInfo.buff_ = OH_AVBuffer_Create(pkt.size);
    auto bufferAddr = OH_AVBuffer_GetAddr(codecBufferInfo.buff_);
    memcpy(bufferAddr, pkt.data, pkt.size);
    codecBufferInfo.attr.size = pkt.size;
    codecBufferInfo.attr.pts = pkt.pts;
    if (pkt.flags == 1) {
        codecBufferInfo.attr.flags = AVCODEC_BUFFER_FLAGS_CODEC_DATA|AVCODEC_BUFFER_FLAGS_SYNC_FRAME;
    } else {
        codecBufferInfo.attr.flags = AVCODEC_BUFFER_FLAGS_NONE;
    }

    ret = this->codecData.InputData(codecBufferInfo, std::chrono::milliseconds(inputTime));
    if (ret == 0) {
        this->decoder.PushInputData(codecBufferInfo);
    }
    OH_AVBuffer_Destroy(codecBufferInfo.buff_);
}

static int qsvenc_get_continuous_buffer(AVFrame *frame, OH_AVFormat *format, CodecBufferInfo*  codecBufferInfoReceive)
{
    int32_t currentWidth = 0;
    int32_t currentHeight = 0;
    int32_t displayWidth = 0;
    int32_t displayHeight = 0;
    int index = 0;
    int pixelFormat[] = {AV_PIX_FMT_NONE, AV_PIX_FMT_YUV420P, AV_PIX_FMT_NV12, AV_PIX_FMT_NV21};
    OH_AVFormat_GetIntValue(format, OH_MD_KEY_PIXEL_FORMAT, &index);
    OH_AVFormat_GetIntValue(format, OH_MD_KEY_WIDTH, &currentWidth);
    OH_AVFormat_GetIntValue(format, OH_MD_KEY_HEIGHT, &currentHeight);
    OH_AVFormat_GetIntValue(format, "display_width", &displayWidth);
    OH_AVFormat_GetIntValue(format, "display_height", &displayHeight);

    if (index > sizeof(pixelFormat) / sizeof(pixelFormat[0])) {
        return -1;
    }
    uint8_t *bufferAddr = OH_AVBuffer_GetAddr(codecBufferInfoReceive->buff_);
    frame->pts = codecBufferInfoReceive->attr.pts;
    frame->pkt_dts = codecBufferInfoReceive->attr.pts;
    frame->width = displayWidth;
    frame->height = displayHeight;
    frame->format = pixelFormat[index];

    int indexY;
    switch (frame->format) {
        case AV_PIX_FMT_NV12:
        case AV_PIX_FMT_NV21:
            frame->linesize[0] = currentWidth;
            frame->linesize[1] = currentWidth;
            indexY = sizeof(uint8_t) * currentWidth * currentHeight;
            frame->data[0] = bufferAddr;
            frame->data[1] = bufferAddr + indexY;
            break;
        case AV_PIX_FMT_YUV420P:
            break;
        case AV_PIX_FMT_RGBA:
            break;
        default:
            LOGE("frame->format failed  = %d\n", frame->format);
            break;
    }
    return 0;
}

int Nv12ToYuv420p(AVFrame *&yuv420p_frame, AVFrame *&nv12_frame, int width, int height)
{
    yuv420p_frame = av_frame_alloc();
    if (!yuv420p_frame) {
        LOGE("nv12_to_yuv420p yuv420p_frame av_frame_alloc failed");
        return -1;
    }
    yuv420p_frame->format = AV_PIX_FMT_YUV420P;
    yuv420p_frame->width = width;
    yuv420p_frame->height = height;
    av_image_alloc(yuv420p_frame->data, yuv420p_frame->linesize, width, height, AV_PIX_FMT_YUV420P, 1);
    struct SwsContext *swsCtx =
        sws_getContext(width, height, AV_PIX_FMT_NV12, width, height, AV_PIX_FMT_YUV420P, 0, nullptr, nullptr, nullptr);
    if (!swsCtx) {
        av_frame_free(&yuv420p_frame);
        LOGE("nv12_to_yuv420p sws_ctx null");
        return -1;
    }
    sws_scale(swsCtx, nv12_frame->data, nv12_frame->linesize, 0, height, yuv420p_frame->data, yuv420p_frame->linesize);
    sws_freeContext(swsCtx);
    return 0;
}

void RecordMediaCodecVideoFrame(FFPlayer *ffp, AVFrame *frame)
{
    if (frame->format == AV_PIX_FMT_NV12 && ffp->record_write_data.isInRecord == OHOS_RECORD_STATUS_ON &&
        ffp->record_write_data.recordFramesQueue && frame->width > 0 && frame->height > 0) {
        AVFrame *yuv420p_frame;
        int result = Nv12ToYuv420p(yuv420p_frame, frame, frame->width, frame->height);
        if (result < 0) {
            return;
        }
        RecordFrameData frData;
        frData.data0 = (uint8_t *)malloc((size_t)yuv420p_frame->linesize[DATA_NUM_0] * yuv420p_frame->height);
        frData.data1 =
            (uint8_t *)malloc((size_t)yuv420p_frame->linesize[DATA_NUM_1] * yuv420p_frame->height / DATA_NUM_2);
        frData.data2 =
            (uint8_t *)malloc((size_t)yuv420p_frame->linesize[DATA_NUM_1] * yuv420p_frame->height / DATA_NUM_2);
        frData.dataNum = FRAME_DATA_NUM_3;
        frData.frameType = OHOS_FRAME_TYPE_VIDEO;
        frData.lineSize0 = yuv420p_frame->linesize[DATA_NUM_0];
        frData.lineSize1 = yuv420p_frame->linesize[DATA_NUM_1];
        frData.lineSize2 = yuv420p_frame->linesize[DATA_NUM_2];
        frData.format = AV_PIX_FMT_YUV420P;
        frData.writeFileStatus = DATA_NUM_0;
        memcpy(frData.data0, yuv420p_frame->data[DATA_NUM_0],
               yuv420p_frame->linesize[DATA_NUM_0] * yuv420p_frame->height);
        memcpy(frData.data1, yuv420p_frame->data[DATA_NUM_1],
               yuv420p_frame->linesize[DATA_NUM_1] * yuv420p_frame->height / DATA_NUM_2);
        memcpy(frData.data2, yuv420p_frame->data[DATA_NUM_2],
               yuv420p_frame->linesize[DATA_NUM_2] * yuv420p_frame->height / DATA_NUM_2);
        int windex = ffp->record_write_data.windex;
        ffp->record_write_data.recordFramesQueue[windex] = frData;
        ffp->record_write_data.windex += DATA_NUM_1;
        ffp->record_write_data.srcFormat.height = yuv420p_frame->height;
        ffp->record_write_data.srcFormat.width = yuv420p_frame->width;
        av_freep(yuv420p_frame->data);
        av_frame_free(&yuv420p_frame);
    }
}

void IJKFF_Pipenode_Opaque::DecoderOutput(AVFrame *frame)
{
    CodecBufferInfo codecBufferInfoReceive;
        bool ret = false;
        ret = this->codecData.OutputData(codecBufferInfoReceive);
        if (!ret) {
            return;
        }
        OH_AVBuffer_GetBufferAttr(codecBufferInfoReceive.buff_, &codecBufferInfoReceive.attr);
        OH_AVFormat *format = OH_VideoDecoder_GetOutputDescription(this->decoder.decoder_);
        if (qsvenc_get_continuous_buffer(frame, format, &codecBufferInfoReceive) < 0) {
            OH_AVBuffer_Destroy(codecBufferInfoReceive.buff_);
            OH_AVFormat_Destroy(format);
            return;
        }
        OH_AVFormat_Destroy(format);
        this->decoder.FreeOutputData(codecBufferInfoReceive.bufferIndex);
        OH_AVBuffer_Destroy(codecBufferInfoReceive.buff_);
        if (codecBufferInfoReceive.attr.flags == AVCODEC_BUFFER_FLAGS_EOS) {
            this->codecData.ShutDown();
        }
    if (ffp->is_screenshot) {
        AVFrame *yuv420p_frame;
        int result = Nv12ToYuv420p(yuv420p_frame, frame, frame->width, frame->height);
        if (result < 0) {
            return;
        }
        ffp->is_screenshot = 0;
        SaveCurrentFramePicture(yuv420p_frame, ffp->screen_file_name);
        free(ffp->screen_file_name);
        av_freep(yuv420p_frame->data);
        av_frame_free(&yuv420p_frame);
        ffp->screen_file_name = NULL;
    }
    RecordMediaCodecVideoFrame(ffp, frame);
}


static int decoder_decode_ohos_frame(FFPlayer *ffp, Decoder *d, AVFrame *frame, IJKFF_Pipenode_Opaque *opaque)
{
    int ret = AVERROR(EAGAIN);
    AVPacket pkt;
    AVFormatContext* fmt_ctx = ffp->is->ic;
    do {
        if (d->queue->nb_packets == 0) {
            SDL_CondSignal(d->empty_queue_cond);
        }

        if (ffp_packet_queue_get_or_buffering(ffp, d->queue, &pkt, &d->pkt_serial, &d->finished) < 0) {
            av_packet_unref(&pkt);
            return -1;
        }
        if (ffp_is_flush_packet(&pkt)) {
            d->finished = 0;
            d->next_pts = d->start_pts;
            d->next_pts_tb = d->start_pts_tb;
        }
    } while (d->queue->serial != d->pkt_serial);

    ret = av_bsf_send_packet(opaque->avbsfContext, &pkt);
    if (ret < 0) {
        LOGE("av_bsf_send_packet failed");
    }
    while (ret >= 0) {
        ret = av_bsf_receive_packet(opaque->avbsfContext, &pkt);
        if (ret == AVERROR_EOF) {
            d->finished = d->pkt_serial;
            avcodec_flush_buffers(d->avctx);
            av_packet_unref(&pkt);
            return 0;
        }
    }

    std::thread DecoderInputThread(&IJKFF_Pipenode_Opaque::DecoderInput, opaque, pkt);
    DecoderInputThread.join();
    av_packet_unref(&pkt);
    std::thread DecoderOutputThread(&IJKFF_Pipenode_Opaque::DecoderOutput, opaque, frame);
    DecoderOutputThread.detach();
    usleep(MILLISECOND * NS_TO_US);
    if (frame->pts < 1) {
        return 0;
    }
    return 1;
}

static int get_video_frame(FFPlayer *ffp, AVFrame *frame, IJKFF_Pipenode_Opaque *opaque)
{
    VideoState *is = ffp->is;
    int gotPicture;

    ffp_video_statistic_l(ffp);
    if ((gotPicture = decoder_decode_ohos_frame(ffp, &is->viddec, frame, opaque)) < 0) {
        return -1;
    }

    if (gotPicture) {
        double dpts = NAN;
        if (frame->pts != AV_NOPTS_VALUE)
            dpts = av_q2d(is->video_st->time_base) * frame->pts;

        frame->sample_aspect_ratio = av_guess_sample_aspect_ratio(is->ic, is->video_st, frame);

        if (ffp->framedrop>0 || (ffp->framedrop && ffp_get_master_sync_type(is) != AV_SYNC_VIDEO_MASTER)) {
            ffp->stat.decode_frame_count++;
            if (frame->pts != AV_NOPTS_VALUE) {
                double diff = dpts - ffp_get_master_clock(is);
                if (!isnan(diff) && fabs(diff) < AV_NOSYNC_THRESHOLD &&
                    diff - is->frame_last_filter_delay < 0 &&
                    is->viddec.pkt_serial == is->vidclk.serial &&
                    is->videoq.nb_packets) {
                    is->frame_drops_early++;
                    is->continuous_frame_drops_early++;
                    if (is->continuous_frame_drops_early > ffp->framedrop) {
                        is->continuous_frame_drops_early = 0;
                    } else {
                        ffp->stat.drop_frame_count++;
                        if (ffp->stat.decode_frame_count > 0) {
                            ffp->stat.drop_frame_rate = static_cast<float>(ffp->stat.drop_frame_count) /
                                static_cast<float>(ffp->stat.decode_frame_count);
                        }
                        av_frame_unref(frame);
                        gotPicture = 0;
                    }
                }
            }
        }
    }

    return gotPicture;
}

static int ffplay_video_ohos_thread(FFPlayer *ffp, IJKFF_Pipenode_Opaque *opaque)
{
    VideoState *is = ffp->is;
    AVFrame *frame = av_frame_alloc();
    frame->format = AV_PIX_FMT_NONE;
    double pts;
    double duration;
    int ret;
    AVRational tb = is->video_st->time_base;
    AVRational frameRate = av_guess_frame_rate(is->ic, is->video_st, NULL);
    int64_t dstPts = -1;
    int64_t lastPts = -1;
    int retryConvertImage = 0;
    int convertFrameCount = 0;
    int interval = 1000;

    ffp_notify_msg2(ffp, FFP_MSG_VIDEO_ROTATION_CHANGED, ffp_get_video_rotate_degrees(ffp));

    if (!frame) {
        return AVERROR(ENOMEM);
    }

    for (;;) {
        ret = get_video_frame(ffp, frame, opaque);
        if (ret < 0) {
            goto the_end;
        }

        if (!ret) {
            continue;
        }

        if (ffp->get_frame_mode) {
            if (!ffp->get_img_info || ffp->get_img_info->count <= 0) {
                av_frame_unref(frame);
                continue;
            }

            lastPts = dstPts;

            if (dstPts < 0) {
                dstPts = ffp->get_img_info->start_time;
            } else {
                dstPts += (ffp->get_img_info->end_time - ffp->get_img_info->start_time) / (ffp->get_img_info->num - 1);
            }

            pts = (frame->pts == AV_NOPTS_VALUE) ? NAN : frame->pts * av_q2d(tb);
            pts = pts * interval;
            if (pts >= dstPts) {
                while (retryConvertImage <= MAX_RETRY_CONVERT_IMAGE) {
                    ret = convert_image(ffp, frame, (int64_t)pts, frame->width, frame->height);
                    if (!ret) {
                        convertFrameCount++;
                        break;
                    }
                    retryConvertImage++;
                    av_log(NULL, AV_LOG_ERROR, "convert image error retryConvertImage = %d\n", retryConvertImage);
                }

                retryConvertImage = 0;
                if (ret || ffp->get_img_info->count <= 0) {
                    if (ret) {
                        av_log(NULL, AV_LOG_ERROR, "convert image abort ret = %d\n", ret);
                        ffp_notify_msg3(ffp, FFP_MSG_GET_IMG_STATE, 0, ret);
                    } else {
                        LOGE("convert image complete convertFrameCount = %d\n", convertFrameCount);
                    }
                    goto the_end;
                }
            } else {
                dstPts = lastPts;
            }
            av_frame_unref(frame);
            continue;
        }

            duration = (frameRate.num && frameRate.den ? av_q2d((AVRational){frameRate.den, frameRate.num}) : 0);
            pts = (frame->pts == AV_NOPTS_VALUE) ? NAN : frame->pts * av_q2d(tb);
            ret = ffp_queue_picture(ffp, frame, pts, duration, frame->pkt_pos, is->viddec.pkt_serial);
            av_frame_unref(frame);
            if (ret < 0) {
                goto the_end;
            }
    }
 the_end:
    av_log(NULL, AV_LOG_INFO, "convert image convertFrameCount = %d\n", convertFrameCount);
    av_bsf_free(&opaque->avbsfContext);
    av_frame_free(&frame);
    return 0;
}


static int func_run_sync(IJKFF_Pipenode *node)
{
    IJKFF_Pipenode_Opaque *opaque = static_cast<IJKFF_Pipenode_Opaque *>(node->opaque);
    return ffplay_video_ohos_thread(opaque->ffp, opaque);
}

static int GetAvbsfContest(std::string bsfName, IJKFF_Pipenode_Opaque *decoderSample, AVCodecParameters *codecpar)
{
    void *i = nullptr;
    const AVBitStreamFilter *aVBitStreamFilter = {nullptr};
    while ((decoderSample->aVBitStreamFilter = av_bsf_iterate(&i))) {
        if (!strcmp(decoderSample->aVBitStreamFilter->name, bsfName.c_str())) {
            break;
        }
    }
    if (decoderSample->aVBitStreamFilter == nullptr) {
        return -1;
    }

    if (av_bsf_alloc(decoderSample->aVBitStreamFilter, &decoderSample->avbsfContext) < 0) {
        return -1;
    }

    if (avcodec_parameters_copy(decoderSample->avbsfContext->par_in, codecpar) < 0) {
        return -1;
    }

    if (av_bsf_init(decoderSample->avbsfContext) < 0) {
        return -1;
    }
    return 0;
}

IJKFF_Pipenode *ffpipenode_create_video_decoder_from_ohos_mediacodec(FFPlayer *ffp, IJKFF_Pipeline *pipeline,
    SDL_Vout *vout)
{
    std::string bsfName;
    AVStream *st = ffp->is->video_st;
    IJKFF_Pipenode *node = ffpipenode_alloc(sizeof(IJKFF_Pipenode_Opaque));
    IJKFF_Pipenode_Opaque *decoderSample = new IJKFF_Pipenode_Opaque();
    node->opaque = decoderSample;
    decoderSample->ffp = ffp;
    decoderSample->pipeline = pipeline;
    decoderSample->weakVout = vout;
    decoderSample->codecpar = avcodec_parameters_alloc();
    if (!decoderSample->codecpar) {
        return nullptr;
    }

    if (avcodec_parameters_from_context(decoderSample->codecpar, ffp->is->viddec.avctx) < 0) {
        return nullptr;
    }

    decoderSample->formatInfoEntry.fps = av_q2d(ffp->is->video_st->avg_frame_rate);
    decoderSample->formatInfoEntry.videoHeight = decoderSample->codecpar->height;
    decoderSample->formatInfoEntry.videoWidth = decoderSample->codecpar->width;
    decoderSample->codecData.formatInfo = &decoderSample->formatInfoEntry;

    switch (decoderSample->codecpar->codec_id) {
        case AV_CODEC_ID_H264:
            bsfName = "h264_mp4toannexb";
            decoderSample->decoder.Create(OH_AVCODEC_MIMETYPE_VIDEO_AVC);
            break;
        case AV_CODEC_ID_HEVC:
            bsfName = "hevc_mp4toannexb";
            decoderSample->decoder.Create(OH_AVCODEC_MIMETYPE_VIDEO_HEVC);
            break;
        default:
            LOGE("codec_id failed = %d\n", decoderSample->codecpar->codec_id);
            break;
    }

    if (GetAvbsfContest(bsfName, decoderSample, ffp->is->video_st->codecpar) < 0) {
        LOGE("GetAvbsfContest failed");
        delete decoderSample->aVBitStreamFilter;
        av_bsf_free(&decoderSample->avbsfContext);
        return nullptr;
    }

    decoderSample->decoder.Config(&decoderSample->codecData);
    decoderSample->decoder.Start();
    decoderSample->codecData.Start();

    if (ffp->get_img_info != nullptr) {
        GetImgInfo *get_img_info = ffp->get_img_info;
        int fmt = get_img_info->frame_img_codec_ctx->pix_fmt;
    }

    node->func_destroy = func_destroy;
    node->func_run_sync = func_run_sync;
    return node;
}
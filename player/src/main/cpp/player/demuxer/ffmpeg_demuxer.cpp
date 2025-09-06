//
// Created on 2025/8/19.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "ffmpeg_demuxer.h"

bool FFmpegDemuxer::Open(const std::string& url) {
    if (avformat_open_input(&formatCtx, url.c_str(), nullptr, nullptr) != 0)
        return false;
    return avformat_find_stream_info(formatCtx, nullptr) >= 0;
}

void FFmpegDemuxer::Close() {
    if (formatCtx) avformat_close_input(&formatCtx);
}

int FFmpegDemuxer::GetVideoStreamIndex() {
    return av_find_best_stream(formatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
}

int FFmpegDemuxer::GetAudioStreamIndex() {
    return av_find_best_stream(formatCtx, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
}

bool FFmpegDemuxer::ReadPacket(void* packet) {
    return av_read_frame(formatCtx, static_cast<AVPacket*>(packet)) >= 0;
}
//
// Created on 2025/8/19.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_FFMPEG_DEMUXER_H
#define ROHYPLAYER_FFMPEG_DEMUXER_H

#include "player/demuxer/demuxer.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
}

class FFmpegDemuxer : public Demuxer {
public:
    FFmpegDemuxer() : formatCtx(nullptr) {}
    
    bool Open(const std::string& url) override;
    
    void Close() override;
    
    int GetVideoStreamIndex() override;
    
    int GetAudioStreamIndex() override;
    
    bool ReadPacket(void* packet) override;

private:
    AVFormatContext* formatCtx;
};

#endif //ROHYPLAYER_FFMPEG_DEMUXER_H

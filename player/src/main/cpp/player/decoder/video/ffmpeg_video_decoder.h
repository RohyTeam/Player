#ifndef ROHYPLAYER_FFMPEG_VIDEO_DECODER_H
#define ROHYPLAYER_FFMPEG_VIDEO_DECODER_H

#include "video_decoder.h"

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

class FFmpegVideoDecoder : public VideoDecoder {
public:
    FFmpegVideoDecoder();
    ~FFmpegVideoDecoder() override;
    
    bool open(const std::string& filePath) override;
    void close() override;
    bool getNextFrame(uint8_t** data, int* width, int* height, int* linesize) override;

private:
    AVFormatContext* formatCtx_ = nullptr;
    AVCodecContext* codecCtx_ = nullptr;
    AVFrame* frame_ = nullptr;
    AVPacket* packet_ = nullptr;
    SwsContext* swsCtx_ = nullptr;
    int videoStreamIndex_ = -1;
    uint8_t* videoBuffer_ = nullptr;
    int bufferSize_ = 0;
};

#endif //ROHYPLAYER_FFMPEG_VIDEO_DECODER_H

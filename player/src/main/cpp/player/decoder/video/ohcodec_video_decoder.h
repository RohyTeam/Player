#ifndef ROHYPLAYER_OHCODEC_VIDEO_DECODER_H
#define ROHYPLAYER_OHCODEC_VIDEO_DECODER_H

#include <cstdint>
#include <multimedia/player_framework/native_avcodec_videodecoder.h>
#include <multimedia/player_framework/native_avcapability.h>
#include <multimedia/player_framework/native_avcodec_base.h>
#include <multimedia/player_framework/native_avformat.h>
#include <multimedia/player_framework/native_avbuffer.h>
#include <native_buffer/native_buffer.h>
#include <fstream>

class OHCodecVideoDecoder {
    
public:
    OHCodecVideoDecoder(const std::string& codec, bool hardware);
    ~OHCodecVideoDecoder();
    
    void init(uint64_t width, uint64_t height);
private:
    std::string codec;
    bool _hardware;
    
    OH_AVCodec* _av_codec;
    std::shared_ptr<OH_AVFormat> _av_format;
};

#endif //ROHYPLAYER_OHCODEC_VIDEO_DECODER_H

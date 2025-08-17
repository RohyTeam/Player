#ifndef ROHYPLAYER_VIDEO_DECODER_H
#define ROHYPLAYER_VIDEO_DECODER_H

#include <cstdint>
#include <string>

class VideoDecoder {
public:
    virtual ~VideoDecoder() = default;
    virtual bool open(const std::string& filePath) = 0;
    virtual void close() = 0;
    virtual bool getNextFrame(uint8_t** data, int* width, int* height, int* linesize) = 0;
};

#endif //ROHYPLAYER_VIDEO_DECODER_H

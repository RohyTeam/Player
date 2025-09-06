//
// Created on 2025/8/19.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_DEMUXER_H
#define ROHYPLAYER_DEMUXER_H

#include <string>

class Demuxer {
public:
    virtual ~Demuxer() = default;
    virtual bool Open(const std::string& url) = 0;
    virtual void Close() = 0;
    virtual int GetVideoStreamIndex() = 0;
    virtual int GetAudioStreamIndex() = 0;
    virtual bool ReadPacket(void* packet) = 0;
};

#endif //ROHYPLAYER_DEMUXER_H

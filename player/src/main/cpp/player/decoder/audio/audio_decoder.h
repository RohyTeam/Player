#ifndef ROHYPLAYER_AUDIO_DECODER_H
#define ROHYPLAYER_AUDIO_DECODER_H

#include <cstdint>
#include <string>

class AudioDecoder {
public:
    virtual ~AudioDecoder() = default;
    virtual bool open(const std::string& filePath) = 0;
    virtual void close() = 0;
    virtual int getAudioSamples(uint8_t* buffer, int bufferSize) = 0;
};

#endif //ROHYPLAYER_AUDIO_DECODER_H

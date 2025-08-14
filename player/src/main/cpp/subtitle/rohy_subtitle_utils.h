#ifndef ROHYPLAYER_ROHY_SUBTITLE_UTILS_H
#define ROHYPLAYER_ROHY_SUBTITLE_UTILS_H

#include <subtitle/pgs/subtitle.hpp>
#include <ass/ass.h>

class RohySubtitleUtils {
public:
    static uint8_t* ConvertAssImageToRGBA(const ASS_Image* img);
    static uint8_t* GetPgsSubtitleImage(shared_ptr<Pgs::Subtitle> subtitle, int32_t* width, int32_t* height);
};

#endif //ROHYPLAYER_ROHY_SUBTITLE_UTILS_H

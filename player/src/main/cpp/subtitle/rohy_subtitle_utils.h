#ifndef ROHYPLAYER_ROHY_SUBTITLE_UTILS_H
#define ROHYPLAYER_ROHY_SUBTITLE_UTILS_H

#include <ass/ass.h>

class RohySubtitleUtils {
public:
    static uint8_t* ConvertAssImageToRGBA(const ASS_Image* img);
};

#endif //ROHYPLAYER_ROHY_SUBTITLE_UTILS_H

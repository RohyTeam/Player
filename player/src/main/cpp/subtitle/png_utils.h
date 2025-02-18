//
// Created on 2025/2/18.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_PNG_UTILS_H
#define ROHYPLAYER_PNG_UTILS_H

#include <ass/ass.h>
#include <png.h>
#include <vector>

class PngUtils {
public:
    static bool ConvertAssImageToPng(const ASS_Image* image, std::vector<unsigned char>& pngData);
};

#endif //ROHYPLAYER_PNG_UTILS_H

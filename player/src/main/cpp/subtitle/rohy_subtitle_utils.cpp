#include "rohy_subtitle_utils.h"
#include "subtitle/pgs/subtitle.hpp"
#include <cstdint>

uint8_t* RohySubtitleUtils::ConvertAssImageToRGBA(const ASS_Image* img) {
    const int width = img->w;
    const int height = img->h;
    const int src_stride = img->stride;
    const int dst_stride = width * 4;
    uint8_t* rgba_data = new uint8_t[height * dst_stride]();

    uint32_t color = img->color;
    uint8_t r = ((color >> 24) & 0xFF);
    uint8_t g = ((color >> 16) & 0xFF);
    uint8_t b = ((color >> 8) & 0xFF);

    for (int y = 0; y < height; ++y) {
        const uint8_t* src_row = img->bitmap + y * src_stride;
        uint8_t* dst_row = rgba_data + y * dst_stride;

        for (int x = 0; x < width; ++x) {
            uint8_t alpha = src_row[x];
            dst_row[x * 4]     = r;
            dst_row[x * 4 + 1] = g;
            dst_row[x * 4 + 2] = b;
            dst_row[x * 4 + 3] = alpha;
        }
    }

    return rgba_data;
}

uint8_t* RohySubtitleUtils::GetPgsSubtitleImage(shared_ptr<Pgs::Subtitle> subtitle, int32_t* width, int32_t* height) {
    std::vector<std::vector<std::array<uint8_t, 4>>> bitmap = subtitle->getImage(Pgs::ColorSpace::RGBA);
    
    *width = subtitle->getOds(0)->getWidth();
    *height = subtitle->getOds(0)->getHeight();
    const int dst_stride = *width * 4;
    uint8_t* rgba_data = new uint8_t[*height * dst_stride]();

    for (int y = 0; y < *height; ++y) {
        for (int x = 0; x < *width; ++x) {
            uint8_t* dst_row = rgba_data + y * dst_stride;
            
            dst_row[x * 4]     = bitmap[y][x][0];
            dst_row[x * 4 + 1] = bitmap[y][x][1];
            dst_row[x * 4 + 2] = bitmap[y][x][2];
            dst_row[x * 4 + 3] = bitmap[y][x][3];
        }
    }

    return rgba_data;
}
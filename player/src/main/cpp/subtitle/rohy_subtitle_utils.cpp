#include "rohy_subtitle_utils.h"

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
#include "png_utils.h"

struct PngWriteBuffer {
    std::vector<unsigned char> data;
};

void PngWriteCallback(png_structp png_ptr, png_bytep data, png_size_t length) {
    PngWriteBuffer* buffer = static_cast<PngWriteBuffer*>(png_get_io_ptr(png_ptr));
    buffer->data.insert(buffer->data.end(), data, data + length);
}

bool PngUtils::ConvertAssImageToPng(const ASS_Image* image, std::vector<unsigned char>& pngData) {
    int width = image->w;
    int height = image->h;
    uint32_t color = image->color;

    uint8_t alpha_color = (color >> 24) & 0xFF;
    uint8_t red = (color >> 16) & 0xFF;
    uint8_t green = (color >> 8) & 0xFF;
    uint8_t blue = color & 0xFF;

    std::vector<unsigned char> rgba(width * height * 4);
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            uint8_t bitmap_alpha = image->bitmap[y * image->stride + x];
            uint8_t final_alpha = (alpha_color * bitmap_alpha) / 255;

            size_t index = (y * width + x) * 4;
            rgba[index] = red;
            rgba[index + 1] = green;
            rgba[index + 2] = blue;
            rgba[index + 3] = final_alpha;
        }
    }

    png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
    if (!png) return false;

    png_infop info = png_create_info_struct(png);
    if (!info) {
        png_destroy_write_struct(&png, nullptr);
        return false;
    }

    if (setjmp(png_jmpbuf(png))) {
        png_destroy_write_struct(&png, &info);
        return false;
    }

    PngWriteBuffer buffer;
    png_set_write_fn(png, &buffer, PngWriteCallback, nullptr);

    png_set_IHDR(png, info, width, height, 8, PNG_COLOR_TYPE_RGBA,
                 PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
    png_write_info(png, info);

    std::vector<png_bytep> rowPointers(height);
    for (int y = 0; y < height; ++y) {
        rowPointers[y] = &rgba[y * width * 4];
    }

    png_write_image(png, rowPointers.data());
    png_write_end(png, nullptr);
    png_destroy_write_struct(&png, &info);

    pngData.swap(buffer.data);
    
    return true;
}
//
// Created on 2025/2/18.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "subtitle/subtitle_napi.h"
#include "hilog/log.h"
#include "utils/napi_utils.h"
#include <stdio.h>
#include <stdlib.h>
#include "png_utils.h"

uint8_t* ConvertAssImageToRGBA(const ASS_Image* img) {
    const int width = img->w;
    const int height = img->h;
    const int src_stride = img->stride;
    const int dst_stride = width * 4;

    uint8_t* rgba_data = new uint8_t[height * dst_stride];

    for (int y = 0; y < height; ++y) {
        const uint8_t* src_row = img->bitmap + y * src_stride;
        uint8_t* dst_row = rgba_data + y * dst_stride;

        for (int x = 0; x < width; ++x) {
            dst_row[x * 4 + 0] = src_row[x * 4 + 2];
            dst_row[x * 4 + 1] = src_row[x * 4 + 1];
            dst_row[x * 4 + 2] = src_row[x * 4 + 0];
            dst_row[x * 4 + 3] = src_row[x * 4 + 3];
        }
    }

    return rgba_data;
}

void SubtitleRenderer::initASS(char *buf, size_t bufsize) {
    m_assLibrary = ass_library_init();
    if (!m_assLibrary) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to init ass library");
        return;
    }

    m_assRenderer = ass_renderer_init(m_assLibrary);
    if (!m_assRenderer) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to init ass renderer");
        return;
    }
    
    ass_set_fonts(m_assRenderer, "/data/storage/el2/base/haps/player/files/fallback.ttf", "HarmonyOS Sans SC", 1, nullptr, 0);
    
    // char* url = new char[path.size() + 1];
    // std::strcpy(url, path.c_str());
    // OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK!: path is %{public}s", url);
    // m_assTrack = ass_read_file(m_assLibrary, url, nullptr);
    m_assTrack = ass_read_memory(m_assLibrary, buf, bufsize, nullptr);
    if (m_assTrack == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to read subtitle file");
        return;
    }
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "--------------------\n"
                                                    "|| Loaded Subtitle Info ||\n"
                                                    "Language: %{public}s\n"
                                                    "Track type: %{public}d\n"
                                                    "Name: %{public}s\n"
                                                    "--------------------\n",
        m_assTrack->Language, m_assTrack->track_type, m_assTrack->name
    );
}

void SubtitleRenderer::release() {
    if (m_assTrack) 
        ass_free_track(m_assTrack);
    if (m_assRenderer) 
        ass_renderer_done(m_assRenderer);
    if (m_assLibrary) 
        ass_library_done(m_assLibrary);
}

napi_value SubtitleRenderer::Init(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK: init");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    // std::string fileUrl;
    // NapiUtils::JsValueToString(env, args[0], 2048, fileUrl);
    
    void* data;
    size_t length;
    napi_get_buffer_info(env, args[0], &data, &length);
    
    SubtitleRenderer* instance = SubtitleRenderer::GetInstance();
    
    instance->initASS((char*) data, length);
    
    return nullptr;
}

napi_value create_array_buffer_from_rgba(napi_env env, uint8_t* rgba_data, size_t data_size) {
    napi_value array_buffer;
    void* buffer_data = NULL;

    napi_create_arraybuffer(env, data_size, &buffer_data, &array_buffer);

    memcpy(buffer_data, rgba_data, data_size);

    return array_buffer;
}

napi_value convert_ass_image_to_rgba(napi_env env, const ASS_Image* ass_image) {
    size_t rgba_size = ass_image->w * ass_image->h * 4;
    uint8_t* rgba_buffer = (uint8_t*)malloc(rgba_size);
    if (!rgba_buffer) {
        return NULL;
    }

    for (int y = 0; y < ass_image->h; ++y) {
        for (int x = 0; x < ass_image->w; ++x) {
            uint8_t alpha = ass_image->bitmap[y * ass_image->stride + x];

            uint8_t red = (ass_image->color >> 24) & 0xFF;
            uint8_t green = (ass_image->color >> 16) & 0xFF;
            uint8_t blue = (ass_image->color >> 8) & 0xFF;

            size_t index = (y * ass_image->w + x) * 4;

            rgba_buffer[index] = red;
            rgba_buffer[index + 1] = green;
            rgba_buffer[index + 2] = blue;
            rgba_buffer[index + 3] = alpha;
        }
    }
    
    return create_array_buffer_from_rgba(env, rgba_buffer, rgba_size);
}

napi_value SubtitleRenderer::Render(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK: render");
    SubtitleRenderer* instance = SubtitleRenderer::GetInstance();
    if (!instance->m_assRenderer || !instance->m_assTrack) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR! ass renderer or track not found!");
        return nullptr;
    }
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    int64_t time, width, height;
    napi_get_value_int64(env, args[0], &time);
    napi_get_value_int64(env, args[1], &width);
    napi_get_value_int64(env, args[2], &height);
    
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK! requested time is %{public}ld", time);
    
    ass_set_frame_size(instance->m_assRenderer, width, height);
    ASS_Image* img = ass_render_frame(instance->m_assRenderer, instance->m_assTrack, time, nullptr);
    
    if (img == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK! no image in this frame");
        napi_value array;
        napi_create_array_with_length(env, 0, &array);
        return array;
    }
    
    napi_value array;
    napi_create_array(env, &array);

    size_t i = 0;
    while (img != nullptr) {/*
        std::vector<uint8_t> buffer;
        PngUtils::ConvertAssImageToPng(img, buffer);
        
        napi_value array_buffer;
        napi_create_arraybuffer(env, buffer.size(), reinterpret_cast<void**>(buffer.data()), &array_buffer);*/
        
        uint8_t* rgba_data = ConvertAssImageToRGBA(img);
        const size_t buffer_size = img->h * img->w * 4;

        // 创建 ArrayBuffer
        napi_value array_buffer;
        void* buffer_data = nullptr;
        napi_create_arraybuffer(env, buffer_size, &buffer_data, &array_buffer);

        memcpy(buffer_data, rgba_data, buffer_size);
        delete[] rgba_data;
        
        napi_set_element(env, array, i, array_buffer);
        
        i++;
        img = img->next;
    }
    
    return array;
}

napi_value SubtitleRenderer::Release(napi_env env, napi_callback_info info) {
    SubtitleRenderer::GetInstance()->release();
    return nullptr;
}

SubtitleRenderer* SubtitleRenderer::GetInstance()
{
    static SubtitleRenderer subtitleRender;
    return &subtitleRender;
}
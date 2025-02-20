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
#include <ft2build.h>
#include FT_FREETYPE_H
#include <vector>

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
    
    ASS_DefaultFontProvider* providers;
    size_t size;
    ass_get_available_font_providers(m_assLibrary, &providers, &size);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK!: available font providers amount: %{public}ld", size);
    
    if (!memoryFonts_.empty()) {
        for (const auto& [fontName, fontData] : memoryFonts_) {
            OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK!: added font with name %{public}s", fontName.c_str());
            ass_add_font(m_assLibrary, fontName.c_str(),
                                         fontData.fontData, fontData.fontSize);
        }
        ass_set_fonts(m_assRenderer, nullptr, "HarmonyOS Sans SC", 1, nullptr, 1);
    } else {
        OH_LOG_Print(LOG_APP, LOG_WARN, 0, "FontAdd", "No custom fonts available");
    }
    
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
    if (m_assLibrary)  {
        ass_clear_fonts(m_assLibrary);
        ass_library_done(m_assLibrary);
        memoryFonts_.clear();
    }
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

napi_value SubtitleRenderer::AddMemoryFont(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK! add font");
    
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    std::string fontName;
    NapiUtils::JsValueToString(env, args[0], 2048, fontName);
    
    void* data;
    size_t length;
    napi_get_buffer_info(env, args[1], &data, &length);
    
    FontData fontData;
    fontData.fontData = (char*) data;
    fontData.fontSize = length;
    
    SubtitleRenderer::GetInstance()->memoryFonts_[fontName] = fontData;
    
    return nullptr;
}

napi_value SubtitleRenderer::GetFontFamilyName(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK! get font family name");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    std::string fontPath;
    NapiUtils::JsValueToString(env, args[0], 2048, fontPath);
    
    FT_Library library;
    FT_Face face;
    if (FT_Init_FreeType(&library)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "font", "Failed to init freetype2 library");
        return nullptr;
    }

    if (FT_New_Face(library, fontPath.c_str(), 0, &face)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "font", "Failed to load font file");
        FT_Done_FreeType(library);
        return nullptr;
    }
    
    char* familyName = face->family_name;
    napi_value jsValue;
    napi_create_string_utf8(env, familyName, sizeof(familyName), &jsValue);
    
    FT_Done_Face(face);
    FT_Done_FreeType(library);
    
    return jsValue;
}

napi_value GetInternalSubtitles(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK! get font family name");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    std::string filePath;
    NapiUtils::JsValueToString(env, args[0], 2048, filePath);
    
    // TODO: get internal subtitles
    
    return nullptr;
}

uint8_t* ConvertAssImageToRGBA(const ASS_Image* img) {
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
    
    while (img != nullptr) {
        napi_value image_obj;
        napi_create_object(env, &image_obj);

        const int buffer_size = img->w * img->h * 4;
        uint8_t* rgba_buffer = ConvertAssImageToRGBA(img);

        napi_value array_buffer;
        void* buffer_data = nullptr;
        napi_create_arraybuffer(env, buffer_size, &buffer_data, &array_buffer);
        memcpy(buffer_data, rgba_buffer, buffer_size);
        delete[] rgba_buffer;

        napi_value js_width, js_height, js_x, js_y;
        napi_create_int32(env, img->w, &js_width);
        napi_create_int32(env, img->h, &js_height);
        napi_create_int32(env, img->dst_x, &js_x);
        napi_create_int32(env, img->dst_y, &js_y);

        napi_set_named_property(env, image_obj, "buffer", array_buffer);
        napi_set_named_property(env, image_obj, "width", js_width);
        napi_set_named_property(env, image_obj, "height", js_height);
        napi_set_named_property(env, image_obj, "x", js_x);
        napi_set_named_property(env, image_obj, "y", js_y);

        napi_set_element(env, array, i, image_obj);
        i += 1;
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
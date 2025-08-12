//
// Created on 2025/8/12.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "rohy_ass_subtitle_renderer.h"
#include "subtitle/rohy_subtitle_utils.h"
#include "utils/napi_utils.h"
#include "hilog/log.h"
#include <cstdint>

static thread_local napi_ref g_ref = nullptr;

RohyAssSubtitleRenderer::RohyAssSubtitleRenderer() : _env(nullptr), _wrapper(nullptr) {}

RohyAssSubtitleRenderer::~RohyAssSubtitleRenderer() {
    napi_delete_reference(this->_env, this->_wrapper);
}

void RohyAssSubtitleRenderer::Finalize(napi_env env, void *native_object, [[maybe_unused]] void *finalize_hint) {
    RohyAssSubtitleRenderer* casted_object = reinterpret_cast<RohyAssSubtitleRenderer*>(native_object);
    
    if (casted_object->_assTrack) 
        ass_free_track(casted_object->_assTrack);
    if (casted_object->_assRenderer) 
        ass_renderer_done(casted_object->_assRenderer);
    if (casted_object->_assLibrary)  {
        ass_clear_fonts(casted_object->_assLibrary);
        ass_library_done(casted_object->_assLibrary);
    }
    
    casted_object->_memoryFonts.clear();
    
    delete casted_object;
}

napi_value RohyAssSubtitleRenderer::Func_New(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "CreateAssRenderer", "creating subtitle renderer");

    napi_value new_target;
    napi_get_new_target(env, info, &new_target);
    
    if (new_target != nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "CreateAssRenderer", "new target");
        size_t arg_c = 0;
        napi_value args[0];
        napi_value jsThis;
        napi_get_cb_info(env, info, &arg_c, args, &jsThis, nullptr);
        
        RohyAssSubtitleRenderer* native_object = new RohyAssSubtitleRenderer();
        
        native_object->_env = env;
        napi_status status = napi_wrap(env, jsThis, reinterpret_cast<void*>(native_object), RohyAssSubtitleRenderer::Finalize, nullptr, &native_object->_wrapper);
        // napi_status status = napi_wrap(env, jsThis, reinterpret_cast<void*>(native_object), RohyAssSubtitleRenderer::Finalize, nullptr, nullptr); // weak reference
        if (status != napi_ok) {
            OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "CreateAssRenderer", "Failed to bind native object to js object, code: %{public}d", status);
            delete native_object;
            return jsThis;
        }
        
        return jsThis;
    } else {
        size_t arg_c = 0;
        napi_value args[0];
        napi_get_cb_info(env, info, &arg_c, args, nullptr, nullptr);
    
        napi_value cons;
        napi_get_reference_value(env, g_ref, &cons);
        
        napi_value instance;
        napi_new_instance(env, cons, arg_c, args, &instance);
    
        return instance;
    }
}

napi_value RohyAssSubtitleRenderer::Func_Init(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "initializing ass font render");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_value jsThis;
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    RohyAssSubtitleRenderer* native_object;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&native_object));
    
    void* data;
    size_t length;
    napi_get_buffer_info(env, args[0], &data, &length);
    
    native_object->_assLibrary = ass_library_init();
    if (!native_object->_assLibrary) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "failed to init ass library");
        return nullptr;
    }

    native_object->_assRenderer = ass_renderer_init(native_object->_assLibrary);
    if (!native_object->_assRenderer) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "failed to init ass renderer");
        ass_clear_fonts(native_object->_assLibrary);
        ass_library_done(native_object->_assLibrary);
        native_object->_assLibrary = nullptr;
        return nullptr;
    }
    
    ASS_DefaultFontProvider* providers;
    size_t size;
    ass_get_available_font_providers(native_object->_assLibrary, &providers, &size);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "available font providers amount: %{public}ld", size);
    
    if (!native_object->_memoryFonts.empty()) {
        for (const auto& [fontName, fontData] : native_object->_memoryFonts) {
            OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "added font with name %{public}s", fontName.c_str());
            ass_add_font(native_object->_assLibrary, fontName.c_str(),
                                         fontData.fontData, fontData.fontSize);
        }
        ass_set_fonts(native_object->_assRenderer, nullptr, "HarmonyOS Sans SC", 1, nullptr, 1);
    } else {
        OH_LOG_Print(LOG_APP, LOG_WARN, 0, "FontAdd", "No custom fonts available");
    }
    
    native_object->_assTrack = ass_read_memory(native_object->_assLibrary, (char*) data, length, nullptr);
    if (native_object->_assTrack == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "failed to read subtitle file");
        ass_renderer_done(native_object->_assRenderer);
        ass_clear_fonts(native_object->_assLibrary);
        ass_library_done(native_object->_assLibrary);
        native_object->_assRenderer = nullptr;
        native_object->_assLibrary = nullptr;
        return nullptr;
    }
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "--------------------\n"
                                                    "|| Loaded Subtitle Info ||\n"
                                                    "Language: %{public}s\n"
                                                    "Track type: %{public}d\n"
                                                    "Name: %{public}s\n"
                                                    "--------------------\n",
        native_object->_assTrack->Language, native_object->_assTrack->track_type, native_object->_assTrack->name
    );
    
    return nullptr;
}

napi_value RohyAssSubtitleRenderer::Func_AddMemoryFont(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "adding memory font");
    
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    
    napi_value jsThis;
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    RohyAssSubtitleRenderer* native_object;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&native_object));
    
    std::string fontName;
    NapiUtils::JsValueToString(env, args[0], 2048, fontName);
    
    void* data;
    size_t length;
    napi_get_buffer_info(env, args[1], &data, &length);
    
    FontData fontData = {
        .fontData = (char*) data,
        .fontSize = length
    };
    
    native_object->_memoryFonts[fontName] = fontData;
    
    return nullptr;
}

napi_value RohyAssSubtitleRenderer::Func_Render(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "rendering");
    
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    
    napi_value jsThis;
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    RohyAssSubtitleRenderer* native_object;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&native_object));
    
    if (!native_object->_assRenderer || !native_object->_assTrack) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "ass renderer or track not found!");
        return nullptr;
    }
    
    int64_t time, width, height;
    napi_get_value_int64(env, args[0], &time);
    napi_get_value_int64(env, args[1], &width);
    napi_get_value_int64(env, args[2], &height);
    
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "requested time is %{public}ld", time);
    
    ass_set_frame_size(native_object->_assRenderer, width, height);
    ASS_Image* img = ass_render_frame(native_object->_assRenderer, native_object->_assTrack, time, nullptr);
    
    if (img == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "AssSubtitleRenderer", "no image in this frame");
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
        uint8_t* rgba_buffer = RohySubtitleUtils::ConvertAssImageToRGBA(img);

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

napi_value RohyAssSubtitleRenderer::Func_Release(napi_env env, napi_callback_info info) {
    size_t argc = 0;
    napi_value args[0];
    
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    RohyAssSubtitleRenderer* native_object;
    napi_unwrap(env, jsThis, reinterpret_cast<void**>(&native_object));
    
    if (native_object->_assTrack) 
        ass_free_track(native_object->_assTrack);
    if (native_object->_assRenderer) 
        ass_renderer_done(native_object->_assRenderer);
    if (native_object->_assLibrary)  {
        ass_clear_fonts(native_object->_assLibrary);
        ass_library_done(native_object->_assLibrary);
    }
    
    native_object->_memoryFonts.clear();
    
    return nullptr;
}

napi_value RohyAssSubtitleRenderer::Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "init", nullptr, Func_Init, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "addMemoryFont", nullptr, Func_AddMemoryFont, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "render", nullptr, Func_Render, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "release", nullptr, Func_Release, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons; // idk what does this mean, i just do what the doc tell me to do
    napi_define_class(env, "RohyAssSubtitleRenderer", NAPI_AUTO_LENGTH, Func_New, nullptr, 4, desc, &cons);
    napi_create_reference(env, cons, 1, &g_ref);
    napi_set_named_property(env, exports, "RohyAssSubtitleRenderer", cons);
    
    return exports;
}
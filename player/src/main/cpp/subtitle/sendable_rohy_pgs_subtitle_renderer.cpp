//
// Created on 2025/8/14.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "rohy_pgs_subtitle_renderer.h"
#include "metadata/rohy_metadata_getter.h"
#include "subtitle/rohy_subtitle_utils.h"
#include "utils/napi_utils.h"
#include <cstdint>
#include <cstdint>
#include <hilog/log.h>
#include <fstream>

static thread_local napi_ref g_ref = nullptr;

SendableRohyPgsSubtitleRenderer::SendableRohyPgsSubtitleRenderer() : _env(nullptr) {}

SendableRohyPgsSubtitleRenderer::~SendableRohyPgsSubtitleRenderer() {
}

void SendableRohyPgsSubtitleRenderer::Finalize(napi_env env, void *native_object, [[maybe_unused]] void *finalize_hint) {
    SendableRohyPgsSubtitleRenderer* casted_object = reinterpret_cast<SendableRohyPgsSubtitleRenderer*>(native_object);
    casted_object->subtitles.clear();
    delete casted_object;
}

napi_value SendableRohyPgsSubtitleRenderer::Func_New(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "CreatePgsRenderer", "creating pgs subtitle renderer");

    napi_value new_target;
    napi_get_new_target(env, info, &new_target);
    
    if (new_target != nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "CreatePgsRenderer", "new target");
        size_t arg_c = 0;
        napi_value args[0];
        napi_value jsThis;
        napi_get_cb_info(env, info, &arg_c, args, &jsThis, nullptr);
        
        SendableRohyPgsSubtitleRenderer* native_object = new SendableRohyPgsSubtitleRenderer();
        
        native_object->_env = env;
        napi_status status = napi_wrap_sendable(env, jsThis, reinterpret_cast<void*>(native_object), SendableRohyPgsSubtitleRenderer::Finalize, nullptr);
        // napi_status status = napi_wrap(env, jsThis, reinterpret_cast<void*>(native_object), SendableRohyPgsSubtitleRenderer::Finalize, nullptr, nullptr); // weak reference
        if (status != napi_ok) {
            OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "CreatePgsRenderer", "Failed to bind native object to js object, code: %{public}d", status);
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

napi_value SendableRohyPgsSubtitleRenderer::Func_Init(napi_env env, napi_callback_info info) {
    napi_value jsRanges;
    napi_create_sendable_array(env, &jsRanges);

    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "PgsSubtitleRenderer", "initializing pgs subtitle render");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_value jsThis;
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "PgsSubtitleRenderer", "GetContext napi_get_cb_info failed");
        return jsRanges; // empty
    }
    
    SendableRohyPgsSubtitleRenderer* native_object;
    napi_unwrap_sendable(env, jsThis, reinterpret_cast<void**>(&native_object));

    if (native_object->initialized)
        return jsRanges; // empty
    
    std::string fileUrl;
    NapiUtils::JsValueToString(env, args[0], 2048, fileUrl);

    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "PgsSubtitleRenderer", "ready to read pgs subtitle file");
    std::ifstream file(fileUrl, std::ios::binary);
    const std::vector buffer((std::istreambuf_iterator(file)),
                        std::istreambuf_iterator<char>());
    const char* data = buffer.data();
    const size_t size = buffer.size();

    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "PgsSubtitleRenderer", "successfully read pgs subtitle file, ready to decode");
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "PgsSubtitleRenderer", "pgs file url: %{public}s, data size: %{public}zu", fileUrl.c_str(), size);
    native_object->subtitles = Pgs::Subtitle::createAll(data, size);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "PgsSubtitleRenderer", "pgs subtitle file decoded");

    std::vector<shared_ptr<Pgs::Subtitle>> currentSegment;

    int jsRangeIndex = 0;

    for (auto subtitle : native_object->subtitles) {
        if (subtitle->containsImage()) {
            currentSegment.push_back(subtitle);
        } else {
            if (!currentSegment.empty()) {
                SubtitleRange range;
                range.startMs = currentSegment.front()->getPresentationTimeMs();
                range.endMs = subtitle->getPresentationTimeMs();
                range.subtitles = currentSegment;
                native_object->ranges.push_back(range);
                currentSegment.clear();

                napi_value jsIndex, jsStart, jsEnd;

                napi_create_int32(env, jsRangeIndex, &jsIndex);
                napi_create_int32(env, range.startMs, &jsStart);
                napi_create_int32(env, range.endMs, &jsEnd);

                napi_property_descriptor properties[] = {
                    { "index", nullptr, nullptr, nullptr, nullptr, jsIndex, napi_default, nullptr },
                    { "start", nullptr, nullptr, nullptr, nullptr, jsStart, napi_default, nullptr },
                    { "end", nullptr, nullptr, nullptr, nullptr, jsEnd, napi_default, nullptr },
                };

                napi_value jsRangeObj;
                napi_create_sendable_object_with_properties(env, sizeof(properties) / sizeof(properties[0]), properties, &jsRangeObj);
                napi_set_element(env, jsRanges, jsRangeIndex, jsRangeObj);
                jsRangeIndex += 1;
            }
        }
    }

    currentSegment.clear();

    std::sort(native_object->ranges.begin(), native_object->ranges.end(), 
        [](const SubtitleRange& a, const SubtitleRange& b) {
            return a.startMs < b.startMs;
        });

    native_object->initialized = true;

    return jsRanges;
}

napi_value SendableRohyPgsSubtitleRenderer::Func_Render(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "PgsSubtitleRenderer", "rendering frames");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    
    napi_value jsThis;
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    SendableRohyPgsSubtitleRenderer* native_object;
    napi_unwrap_sendable(env, jsThis, reinterpret_cast<void**>(&native_object));
    
    if (!native_object->initialized || native_object->subtitles.empty())
        return nullptr;
    
    int64_t time;
    napi_get_value_int64(env, args[0], &time);
    
    auto range = std::lower_bound(native_object->ranges.begin(), native_object->ranges.end(), time,
        [](const SubtitleRange& seg, long pos) {
            return seg.endMs < pos; // 查找第一个结束时间 >= positionMs 的区间
        });

    if (range == native_object->ranges.end() || !range->contains(time)) {
        return nullptr;
    }

    if (range->subtitles.empty())
        return nullptr;
    
    napi_value array;
    napi_create_sendable_array(env, &array);

    size_t i = 0;

    for (auto subtitle : range->subtitles) {
        if (!subtitle->containsImage())
            continue;
        napi_value image_obj;

        int32_t width;
        int32_t height;
        uint8_t* rgba_buffer = RohySubtitleUtils::GetPgsSubtitleImage(subtitle, &width, &height);
        const int buffer_size = width * height * 4;

        napi_value array_buffer;
        void* buffer_data = nullptr;
        napi_create_sendable_arraybuffer(env, buffer_size, &buffer_data, &array_buffer);
        memcpy(buffer_data, rgba_buffer, buffer_size);
        delete[] rgba_buffer;

        napi_value js_screen_width, js_screen_height, js_width, js_height, js_x, js_y;
        napi_create_int32(env, subtitle->getStreamWidth(), &js_screen_width);
        napi_create_int32(env, subtitle->getStreamHeight(), &js_screen_height);
        napi_create_int32(env, width, &js_width);
        napi_create_int32(env, height, &js_height);
        napi_create_int32(env, subtitle->getXOffset(), &js_x);
        napi_create_int32(env, subtitle->getYOffset(), &js_y);

        napi_property_descriptor properties[] = {
            { "buffer", nullptr, nullptr, nullptr, nullptr, array_buffer, napi_default, nullptr },
            { "screenWidth", nullptr, nullptr, nullptr, nullptr, js_screen_width, napi_default, nullptr },
            { "screenHeight", nullptr, nullptr, nullptr, nullptr, js_screen_height, napi_default, nullptr },
            { "width", nullptr, nullptr, nullptr, nullptr, js_width, napi_default, nullptr },
            { "height", nullptr, nullptr, nullptr, nullptr, js_height, napi_default, nullptr },
            { "x", nullptr, nullptr, nullptr, nullptr, js_x, napi_default, nullptr },
            { "y", nullptr, nullptr, nullptr, nullptr, js_y, napi_default, nullptr },
        };

        napi_create_sendable_object_with_properties(env, sizeof(properties) / sizeof(properties[0]), properties, &image_obj);

        napi_set_element(env, array, i, image_obj);
        i += 1;
    }

    return array;
}

napi_value SendableRohyPgsSubtitleRenderer::Func_RenderByIndex(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "PgsSubtitleRenderer", "rendering frames");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    
    napi_value jsThis;
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    SendableRohyPgsSubtitleRenderer* native_object;
    napi_unwrap_sendable(env, jsThis, reinterpret_cast<void**>(&native_object));
    
    if (!native_object->initialized || native_object->subtitles.empty())
        return nullptr;
    
    int64_t index;
    napi_get_value_int64(env, args[0], &index);

    if (index < 0 || index >= native_object->ranges.size())
        return nullptr;

    auto range = native_object->ranges[index];

    if (range.subtitles.empty())
        return nullptr;
    
    napi_value array;
    napi_create_sendable_array(env, &array);

    size_t i = 0;

    for (auto subtitle : range.subtitles) {
        if (!subtitle->containsImage())
            continue;
        napi_value image_obj;

        int32_t width;
        int32_t height;
        uint8_t* rgba_buffer = RohySubtitleUtils::GetPgsSubtitleImage(subtitle, &width, &height);
        const int buffer_size = width * height * 4;

        napi_value array_buffer;
        void* buffer_data = nullptr;
        napi_create_sendable_arraybuffer(env, buffer_size, &buffer_data, &array_buffer);
        memcpy(buffer_data, rgba_buffer, buffer_size);
        delete[] rgba_buffer;

        napi_value js_screen_width, js_screen_height, js_width, js_height, js_x, js_y;
        napi_create_int32(env, subtitle->getStreamWidth(), &js_screen_width);
        napi_create_int32(env, subtitle->getStreamHeight(), &js_screen_height);
        napi_create_int32(env, width, &js_width);
        napi_create_int32(env, height, &js_height);
        napi_create_int32(env, subtitle->getXOffset(), &js_x);
        napi_create_int32(env, subtitle->getYOffset(), &js_y);

        napi_property_descriptor properties[] = {
            { "buffer", nullptr, nullptr, nullptr, nullptr, array_buffer, napi_default, nullptr },
            { "screenWidth", nullptr, nullptr, nullptr, nullptr, js_screen_width, napi_default, nullptr },
            { "screenHeight", nullptr, nullptr, nullptr, nullptr, js_screen_height, napi_default, nullptr },
            { "width", nullptr, nullptr, nullptr, nullptr, js_width, napi_default, nullptr },
            { "height", nullptr, nullptr, nullptr, nullptr, js_height, napi_default, nullptr },
            { "x", nullptr, nullptr, nullptr, nullptr, js_x, napi_default, nullptr },
            { "y", nullptr, nullptr, nullptr, nullptr, js_y, napi_default, nullptr },
        };

        napi_create_sendable_object_with_properties(env, sizeof(properties) / sizeof(properties[0]), properties, &image_obj);

        napi_set_element(env, array, i, image_obj);
        i += 1;
    }

    return array;
}

napi_value SendableRohyPgsSubtitleRenderer::Func_GetMaxDuration(napi_env env, napi_callback_info info) {
    size_t argc = 0;
    napi_value args[0];
    
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    SendableRohyPgsSubtitleRenderer* native_object;
    napi_unwrap_sendable(env, jsThis, reinterpret_cast<void**>(&native_object));

    return NapiUtils::Int32ToJsNumber(env, native_object->subtitles.back()->getPresentationTimeMs());
}

napi_value SendableRohyPgsSubtitleRenderer::Func_Release(napi_env env, napi_callback_info info) {
    size_t argc = 0;
    napi_value args[0];
    
    napi_value jsThis;
    napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    
    SendableRohyPgsSubtitleRenderer* native_object;
    napi_unwrap_sendable(env, jsThis, reinterpret_cast<void**>(&native_object));

    if (!native_object->initialized)
        return nullptr;

    native_object->subtitles.clear();
    native_object->initialized = false;
    
    return nullptr;
}


napi_value SendableRohyPgsSubtitleRenderer::Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "sendableInit", nullptr, Func_Init, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "sendableRender", nullptr, Func_Render, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "sendableRenderByIndex", nullptr, Func_RenderByIndex, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "senableGetMaxDuration", nullptr, Func_GetMaxDuration, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "sendableRelease", nullptr, Func_Release, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_value cons; // idk what does this mean, i just do what the doc tell me to do
    napi_define_sendable_class(env, "SendableRohyPgsSubtitleRenderer", NAPI_AUTO_LENGTH, Func_New, nullptr, sizeof(desc) / sizeof(desc[0]), desc, nullptr, &cons);
    napi_create_reference(env, cons, 1, &g_ref);
    napi_set_named_property(env, exports, "SendableRohyPgsSubtitleRenderer", cons);
    
    return exports;
}
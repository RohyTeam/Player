//
// Created on 2025/8/14.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_ROHY_PGS_SUBTITLE_RENDERER_H
#define ROHYPLAYER_ROHY_PGS_SUBTITLE_RENDERER_H

#include "napi/native_api.h"
#include "subtitle/pgs/subtitle.hpp"

struct SubtitleRange {
    long startMs;
    long endMs;
    std::vector<shared_ptr<Pgs::Subtitle>> subtitles;

    bool contains(long positionMs) const {
        return positionMs >= startMs && positionMs <= endMs;
    }
};

class RohyPgsSubtitleRenderer {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static void Finalize(napi_env env, void* native_object, void* finalize_hint);
private:
    explicit RohyPgsSubtitleRenderer();
    ~RohyPgsSubtitleRenderer();
    
    static napi_value Func_New(napi_env env, napi_callback_info info);
    static napi_value Func_Init(napi_env env, napi_callback_info info);
    static napi_value Func_Render(napi_env env, napi_callback_info info);
    static napi_value Func_Release(napi_env env, napi_callback_info info);
    
    napi_env _env;
    napi_ref _wrapper;
    
    bool initialized = false;
    std::vector<shared_ptr<Pgs::Subtitle>> subtitles;
    std::vector<SubtitleRange> ranges;
};

#endif //ROHYPLAYER_ROHY_PGS_SUBTITLE_RENDERER_H

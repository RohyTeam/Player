//
// Created on 2025/8/12.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_ROHY_ASS_SUBTITLE_RENDERER_H
#define ROHYPLAYER_ROHY_ASS_SUBTITLE_RENDERER_H

#include "napi/native_api.h"
#include <map>
#include <ass/ass.h>
#include <string>

struct FontData {
    char* fontData;
    size_t fontSize;
};

class RohyAssSubtitleRenderer {
public:
    static napi_value Init(napi_env env, napi_value exports);
    static void Finalize(napi_env env, void* native_object, void* finalize_hint);
private:
    explicit RohyAssSubtitleRenderer();
    ~RohyAssSubtitleRenderer();
    
    static napi_value Func_New(napi_env env, napi_callback_info info);
    static napi_value Func_Init(napi_env env, napi_callback_info info);
    static napi_value Func_AddMemoryFont(napi_env env, napi_callback_info info);
    static napi_value Func_Render(napi_env env, napi_callback_info info);
    static napi_value Func_Release(napi_env env, napi_callback_info info);
    
    napi_env _env;
    napi_ref _wrapper;
    
    std::map<std::string, FontData> _memoryFonts;
    ASS_Library* _assLibrary = nullptr;
    ASS_Renderer* _assRenderer = nullptr;
    ASS_Track* _assTrack = nullptr;
};

#endif //ROHYPLAYER_ROHY_ASS_SUBTITLE_RENDERER_H

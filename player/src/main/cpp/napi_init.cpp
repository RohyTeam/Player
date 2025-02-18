#include "napi/native_api.h"
#include "subtitle/subtitle_napi.h"

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "Subtitle_Init", nullptr, SubtitleRenderer::Init, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "Subtitle_Render", nullptr, SubtitleRenderer::Render, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "Subtitle_Release", nullptr, SubtitleRenderer::Release, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "player",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterPlayerModule(void)
{
    napi_module_register(&demoModule);
}

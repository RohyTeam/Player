#include "subtitle/rohy_ass_subtitle_renderer.h"
#include "subtitle/rohy_pgs_subtitle_renderer.h"
#include "utils/napi_utils.h"

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    RohyAssSubtitleRenderer::Init(env, exports);
    RohyPgsSubtitleRenderer::Init(env, exports);
    SendableRohyPgsSubtitleRenderer::Init(env, exports);
    return exports;
}
EXTERN_C_END

static napi_module rohySubtitleModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "rohy_subtitle",
    .nm_priv = nullptr,
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterPlayerModule(void)
{
    napi_module_register(&rohySubtitleModule);
}

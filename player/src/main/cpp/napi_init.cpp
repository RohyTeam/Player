#include "napi/native_api.h"
#include "utils/napi_utils.h"

static napi_value TestFunction(napi_env env, napi_callback_info info)
{
    napi_value test_object;
    napi_create_object(env, &test_object);
    NapiUtils::SetPropertyStringValue(env, test_object, "name", "hello, world");
    NapiUtils::SetPropertyNumberValue(env, test_object, "age", 22);
    NapiUtils::SetPropertyBooleanValue(env, test_object, "graduate", false);
    return test_object;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "testFunction", nullptr, TestFunction, nullptr, nullptr, nullptr, napi_default, nullptr }
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

#include <hilog/log.h>
#include <native_window/external_window.h>
#include "ace/xcomponent/native_interface_xcomponent.h"
#include "player/rohy_player_window_manager.h"
#include "utils/napi_utils.h"
#include "rohy_player.h"

void RohyPlayer_OnSurfaceCreatedCallback(OH_NativeXComponent *component, void *window) {
    char name[OH_XCOMPONENT_ID_LEN_MAX] = {0};
    uint64_t name_len = OH_XCOMPONENT_ID_LEN_MAX;
    if (component != nullptr) {
      OH_NativeXComponent_GetXComponentId(component, name, &name_len);
    }
    std::shared_ptr<RohyPlayerNativeWindow> temp = std::make_shared<RohyPlayerNativeWindow>();
    temp->nativeWindow = window;
    temp->id = name;
    temp->nativeXComponent = component;
    RohyPlayerWindowManager::getInstance()->addNativeXComponent(temp);
}

void RohyPlayer_OnSurfaceChangedCallback(OH_NativeXComponent *component, void *window) {
}

void RohyPlayer_OnSurfaceDestroyedCallback(OH_NativeXComponent *component, void *window) {
    char name[OH_XCOMPONENT_ID_LEN_MAX] = {0};
    uint64_t name_len = OH_XCOMPONENT_ID_LEN_MAX;
    if (component != nullptr) {
      OH_NativeXComponent_GetXComponentId(component, name, &name_len);
    }
    RohyPlayerWindowManager::getInstance()->removeNativeXComponent(name);
}

void RohyPlayer_DispatchTouchEventCallback(OH_NativeXComponent *component, void *window) {
}

napi_value RohyPlayer_Test(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "Testing Rohy Player");
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    std::string windowId;
    NapiUtils::JsValueToString(env, args[0], 2048, windowId);
    
    std::string path;
    NapiUtils::JsValueToString(env, args[1], 2048, path);
    
    auto player = std::make_shared<RohyPlayer>(windowId);
    
    if (player->load(path)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: File loaded");
        player->play();
    } else {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: Failed to load file");
    }
    
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "RohyPlayer_test", nullptr, RohyPlayer_Test, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    OH_NativeXComponent *nativeXComponent = nullptr;
    static OH_NativeXComponent_Callback nativeXComponentCallback;
    napi_status status;
    napi_value exportInstance = nullptr;
    status = napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance);
    if (status == napi_ok) {
        status = napi_unwrap(env, exportInstance,
                             reinterpret_cast<void **>(&nativeXComponent));
        if (status == napi_ok) {
            nativeXComponentCallback.OnSurfaceCreated = RohyPlayer_OnSurfaceCreatedCallback;
            nativeXComponentCallback.OnSurfaceChanged = RohyPlayer_OnSurfaceChangedCallback;
            nativeXComponentCallback.OnSurfaceDestroyed = RohyPlayer_OnSurfaceDestroyedCallback;
            nativeXComponentCallback.DispatchTouchEvent = RohyPlayer_DispatchTouchEventCallback;
            OH_NativeXComponent_RegisterCallback(nativeXComponent, &nativeXComponentCallback);
        }
    }
    return exports;
}
EXTERN_C_END

static napi_module rohyPlayerModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "rohy_player",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterPlayerModule(void)
{
    napi_module_register(&rohyPlayerModule);
}

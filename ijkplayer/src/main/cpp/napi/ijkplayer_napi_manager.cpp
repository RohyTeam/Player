/*
 * Copyright (C) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "ijkplayer_napi_manager.h"

IJKPlayerNapiManager IJKPlayerNapiManager::ijkPlayerNapiManager_;

IJKPlayerNapi *IJKPlayerNapiManager::getIjkPlayerNapi(std::string &id) {
    if (pluginIjkPlayerNapiMap_.find(id) == pluginIjkPlayerNapiMap_.end()) {
        IJKPlayerNapi *instance = IJKPlayerNapi::getInstance(id);
        pluginIjkPlayerNapiMap_[id] = instance;
        return instance;
    } else {
        return pluginIjkPlayerNapiMap_[id];
    }
}

bool IJKPlayerNapiManager::initXComponent(napi_env env, napi_value exports) {
    LOGI("napi-->initXComponent");
    napi_status status;
    napi_value exportInstance = nullptr;
    OH_NativeXComponent *nativeXComponent = nullptr;
    int32_t ret;
    char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {};
    uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;
    status = napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance);
    if (status != napi_ok) {
        return false;
    }
    LOGI("napi-->initXComponent napi_get_named_property");
    status = napi_unwrap(env, exportInstance, reinterpret_cast<void **>(&nativeXComponent));
    if (status != napi_ok) {
        return false;
    }
    LOGI("napi-->initXComponent napi_unwrap");
    ret = OH_NativeXComponent_GetXComponentId(nativeXComponent, idStr, &idSize);
    if (ret != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
        return false;
    }
    std::string id(idStr);
    xcomponentId_ = id;
    LOGI("napi-->initXComponent OH_NativeXComponent_GetXComponentId:%s", (char *)id.c_str());
    auto context = IJKPlayerNapiManager::getInstance();
    if (context) {
        auto ijkplayerNapi = context->getIjkPlayerNapi(id);
        ijkplayerNapi->setNativeXComponent(nativeXComponent);
        ijkplayerNapi->Export(env, exports);
    }
    LOGI("napi-->initXComponent-->end");
    return true;
}

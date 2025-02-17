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

#ifndef ijkplayer_ijkplayer_napi_manager_H
#define ijkplayer_ijkplayer_napi_manager_H
#include "ijkplayer_napi.h"
#include "../utils/ohoslog/ohos_log.h"
#include <napi/native_api.h>
#include <uv.h>
class IJKPlayerNapiManager {

  public:
    ~IJKPlayerNapiManager() {}
    static IJKPlayerNapiManager *getInstance() {
        return &IJKPlayerNapiManager::ijkPlayerNapiManager_;
    }
    IJKPlayerNapi *getIjkPlayerNapi(std::string &id);
    bool initXComponent(napi_env env, napi_value exports);

  public:
    napi_env mainEnv_ = nullptr;
    uv_loop_t *mainLoop_ = nullptr;
    uv_async_t mainOnMessageSignal_{};
    static IJKPlayerNapiManager ijkPlayerNapiManager_;
    std::string xcomponentId_;
    std::unordered_map<std::string, IJKPlayerNapi *> pluginIjkPlayerNapiMap_;
};

#endif //ijkplayer_ijkplayer_napi_manager_H

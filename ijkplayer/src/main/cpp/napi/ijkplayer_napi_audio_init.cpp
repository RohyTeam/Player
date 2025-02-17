/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
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

#include "ijkplayer_napi.h"

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        DECLARE_NAPI_FUNCTION("_setDataSource", IJKPlayerNapi::setDataSource),
        DECLARE_NAPI_FUNCTION("_setOption", IJKPlayerNapi::setOption),
        DECLARE_NAPI_FUNCTION("_setOptionLong", IJKPlayerNapi::setOptionLong),
        DECLARE_NAPI_FUNCTION("_prepareAsync", IJKPlayerNapi::prepareAsync),
        DECLARE_NAPI_FUNCTION("_start", IJKPlayerNapi::start),
        DECLARE_NAPI_FUNCTION("_stop", IJKPlayerNapi::stop),
        DECLARE_NAPI_FUNCTION("_pause", IJKPlayerNapi::pause),
        DECLARE_NAPI_FUNCTION("_reset", IJKPlayerNapi::reset),
        DECLARE_NAPI_FUNCTION("_release", IJKPlayerNapi::release),
        DECLARE_NAPI_FUNCTION("_seekTo", IJKPlayerNapi::seekTo),
        DECLARE_NAPI_FUNCTION("_isPlaying", IJKPlayerNapi::isPlaying),
        DECLARE_NAPI_FUNCTION("_setMessageListener", IJKPlayerNapi::setMessageListener),
        DECLARE_NAPI_FUNCTION("_getDuration", IJKPlayerNapi::getDuration),
        DECLARE_NAPI_FUNCTION("_getCurrentPosition", IJKPlayerNapi::getCurrentPosition),
        DECLARE_NAPI_FUNCTION("_setPropertyFloat", IJKPlayerNapi::setPropertyFloat),
        DECLARE_NAPI_FUNCTION("_getPropertyFloat", IJKPlayerNapi::getPropertyFloat),
        DECLARE_NAPI_FUNCTION("_setPropertyLong", IJKPlayerNapi::setPropertyLong),
        DECLARE_NAPI_FUNCTION("_getPropertyLong", IJKPlayerNapi::getPropertyLong),
        DECLARE_NAPI_FUNCTION("_getAudioSessionId", IJKPlayerNapi::getAudioSessionId),
        DECLARE_NAPI_FUNCTION("_setVolume", IJKPlayerNapi::setVolume),
        DECLARE_NAPI_FUNCTION("_setLoopCount", IJKPlayerNapi::setLoopCount),
        DECLARE_NAPI_FUNCTION("_getLoopCount", IJKPlayerNapi::getLoopCount),
        DECLARE_NAPI_FUNCTION("_getVideoCodecInfo", IJKPlayerNapi::getVideoCodecInfo),
        DECLARE_NAPI_FUNCTION("_getAudioCodecInfo", IJKPlayerNapi::getAudioCodecInfo),
        DECLARE_NAPI_FUNCTION("_setStreamSelected", IJKPlayerNapi::setStreamSelected),
        DECLARE_NAPI_FUNCTION("_getMediaMeta", IJKPlayerNapi::getMediaMeta),
        DECLARE_NAPI_FUNCTION("_nativeOpenlog", IJKPlayerNapi::nativeOpenlog),
        DECLARE_NAPI_FUNCTION("_native_setup", IJKPlayerNapi::native_setup),
        DECLARE_NAPI_FUNCTION("_native_setup_audio", IJKPlayerNapi::native_setup_audio)
    };
    napi_value ijkAudio = nullptr;
    const char *classBindName = "IJKPlayerNapi";
    int methodSize = std::end(desc) - std::begin(desc);
    napi_define_class(env, classBindName, strlen(classBindName), IJKPlayerNapi::JsConstructor, nullptr, methodSize,
                      desc, &ijkAudio);
    napi_set_named_property(env, exports, "newIjkPlayerAudio", ijkAudio);
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    return exports;
}
EXTERN_C_END

static napi_module ijkplayerAudioModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "ijkplayer_audio_napi",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterModule(void) {
    napi_module_register(&ijkplayerAudioModule);
}
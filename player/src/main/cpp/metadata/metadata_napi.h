//
// Created on 2025/2/19.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_METADATA_NAPI_H
#define ROHYPLAYER_METADATA_NAPI_H

#include <napi/native_api.h>

class MetadataManager {
public:
    static napi_value GetMetadata(napi_env env, napi_callback_info info);
};

#endif //ROHYPLAYER_METADATA_NAPI_H

//
// Created on 2025/2/8.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef HONEY_NAPI_UTILS_H
#define HONEY_NAPI_UTILS_H

#include "napi/native_api.h"
#include <string>

class NapiUtils {
public:
    static void JsValueToString(const napi_env &env, const napi_value &value, const int32_t bufLen,
        std::string &target);
};

#endif //HONEY_NAPI_UTILS_H

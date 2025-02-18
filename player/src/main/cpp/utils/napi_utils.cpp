//
// Created on 2025/2/8.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,

#include "napi_utils.h"

void NapiUtils::JsValueToString(const napi_env & env, const napi_value & value, const int32_t bufLen, std::string & target)
{
    if (bufLen <= 0 || bufLen > 2048) {
        return;
    }

    std::unique_ptr < char[] > buf = std::make_unique < char[] >(bufLen);
    if (buf.get() == nullptr) {
        return;
    }
    (void) memset(buf.get(), 0, bufLen);
    size_t result = 0;
    napi_get_value_string_utf8(env, value, buf.get(), bufLen, &result);
    target = buf.get();
}



#ifndef ROHY_NAPI_UTILS_H
#define ROHY_NAPI_UTILS_H

#include "napi/native_api.h"
#include <cmath>
#include <string>

class NapiUtils {
public:
    static void SetPropertyUndefined(napi_env env, napi_value obj, const char* propertyName);
    static void SetPropertyStringValue(napi_env env, napi_value obj, const char* propertyName, const char* value);
    static void SetPropertyStringValue(napi_env env, napi_value obj, const char* propertyName, std::string value);
    static void SetPropertyNumberValue(napi_env env, napi_value obj, const char* propertyName, int64_t value);
    static void SetPropertyDoubleValue(napi_env env, napi_value obj, const char* propertyName, double_t value);
    static void SetPropertyBooleanValue(napi_env env, napi_value obj, const char* propertyName, bool value);
    static void SetPropertyStringValueOrUndefined(napi_env env, napi_value obj, const char* propertyName, const char* value);
    static void SetPropertyStringValueOrUndefined(napi_env env, napi_value obj, const char* propertyName, std::string value);
    static void SetPropertyNumberValueOrUndefined(napi_env env, napi_value obj, const char* propertyName, int64_t* value);
    static void SetPropertyBooleanValueOrUndefined(napi_env env, napi_value obj, const char* propertyName, bool* value);
    static void JsValueToString(const napi_env &env, const napi_value &value, const int32_t bufLen, std::string &target);
    static napi_value Int32ToJsNumber(napi_env env, int value);
    static napi_value CStringToJsString(napi_env env, const char* value);
};

#endif // ROHY_NAPI_UTILS_H
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

napi_value NapiUtils::CStringToJsString(napi_env env, const char* value) {
    napi_value jsValue;
    napi_create_string_utf8(env, value, sizeof(value), &jsValue);
    return jsValue;
}

void NapiUtils::SetPropertyUndefined(napi_env env, napi_value obj, const char* propertyName) {
    napi_value jsValue;
    napi_get_undefined(env, &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

void NapiUtils::SetPropertyNumberValue(napi_env env, napi_value obj, const char* propertyName, int64_t value) {
    napi_value jsValue;
    napi_create_int64(env, value, &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

void NapiUtils::SetPropertyBooleanValue(napi_env env, napi_value obj, const char* propertyName, bool value) {
    napi_value jsValue;
    napi_get_boolean(env, value, &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

void NapiUtils::SetPropertyStringValue(napi_env env, napi_value obj, const char* propertyName, const char* value) {
    napi_value jsValue;
    napi_create_string_utf8(env, value, strlen(value), &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

void NapiUtils::SetPropertyStringValue(napi_env env, napi_value obj, const char* propertyName, std::string value) {
    napi_value jsValue;
    napi_create_string_utf8(env, value.c_str(), value.length(), &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

void NapiUtils::SetPropertyNumberValueOrUndefined(napi_env env, napi_value obj, const char* propertyName, int64_t* value) {
    napi_value jsValue;
    value ? napi_create_int64(env, *value, &jsValue) : napi_get_undefined(env, &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

void NapiUtils::SetPropertyBooleanValueOrUndefined(napi_env env, napi_value obj, const char* propertyName, bool* value) {
    napi_value jsValue;
    value ? napi_get_boolean(env, *value, &jsValue) : napi_get_undefined(env, &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

void NapiUtils::SetPropertyStringValueOrUndefined(napi_env env, napi_value obj, const char* propertyName, const char* value) {
    napi_value jsValue;
    value ? napi_create_string_utf8(env, value, std::string(value).length(), &jsValue) : napi_get_undefined(env, &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

void NapiUtils::SetPropertyStringValueOrUndefined(napi_env env, napi_value obj, const char* propertyName, std::string value) {
    napi_value jsValue;
    !value.empty() ? napi_create_string_utf8(env, value.c_str(), value.length(), &jsValue) : napi_get_undefined(env, &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}
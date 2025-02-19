//
// Created on 2025/2/18.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef HONEY_SUBTITLE_NAPI_H
#define HONEY_SUBTITLE_NAPI_H

#include <napi/native_api.h>
#include <ace/xcomponent/native_interface_xcomponent.h>
#include <native_window/external_window.h>
#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>
#include <ass/ass.h>
#include <map>

struct FontData {
    char* fontData;
    size_t fontSize;
};

class SubtitleRenderer {
public:
    static SubtitleRenderer* GetInstance();
    static napi_value Init(napi_env env, napi_callback_info info);
    static napi_value AddFont(napi_env env, napi_callback_info info);
    static napi_value Render(napi_env env, napi_callback_info info);
    static napi_value Release(napi_env env, napi_callback_info info);
private:
    void initASS(char *buf, size_t bufsize);
    void release();
public:
    std::map<std::string, FontData> fonts_;
private:
    ASS_Library* m_assLibrary = nullptr;
    ASS_Renderer* m_assRenderer = nullptr;
    ASS_Track* m_assTrack = nullptr;
};

#endif //HONEY_SUBTITLE_NAPI_H

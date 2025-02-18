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
    bool Export(napi_env env, napi_value exports);
private:
    void initEGL();
    void initASS(char *buf, size_t bufsize);
    void compileShader();
    void release();
    void renderImage(ASS_Image* img);
public:
    std::map<std::string, FontData> fonts_;
    
    OH_NativeXComponent* nativeXComponent_ = nullptr;
    OHNativeWindow* nativeWindow_ = nullptr;
    uint64_t height_;
    uint64_t width_;
    
    EGLDisplay eglDisplay_ = nullptr;
    EGLSurface eglSurface_ = nullptr;
    EGLContext eglContext_ = nullptr;
    int wakeup = 0;
private:
    ASS_Library* m_assLibrary = nullptr;
    ASS_Renderer* m_assRenderer = nullptr;
    ASS_Track* m_assTrack = nullptr;
    
    GLuint m_program = 0;
    GLint m_positionLoc;
    GLint m_texCoordLoc;
    GLint m_samplerLoc;
    
    OH_NativeXComponent_Callback callback_;
};

#endif //HONEY_SUBTITLE_NAPI_H

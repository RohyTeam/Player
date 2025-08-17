//
// Created on 2025/8/16.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_ROHY_PLAYER_H
#define ROHYPLAYER_ROHY_PLAYER_H

#include <string>
#include <memory>
#include <thread>
#include <mutex>
#include "decoder/video/video_decoder.h"
#include "decoder/audio/audio_decoder.h"
#include "rohy_player_window_manager.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <fstream>
#include <unistd.h>

class RohyPlayer {
public:
    RohyPlayer(const std::string& windowId);
    ~RohyPlayer();
    
    bool load(const std::string& filePath);
    void play();
    void pause();
    void stop();
    
private:
    void renderLoop();
    bool initEGL();
    void renderFrame(GLuint texture);
    void cleanup();

    std::string windowId_;
    std::unique_ptr<VideoDecoder> videoDecoder_;
    std::unique_ptr<AudioDecoder> audioDecoder_;
    std::thread renderThread_;
    bool isPlaying_ = false;
    bool stopRequested_ = false;
    
    // EGL相关成员
    EGLDisplay eglDisplay_ = EGL_NO_DISPLAY;
    EGLContext eglContext_ = EGL_NO_CONTEXT;
    EGLSurface eglSurface_ = EGL_NO_SURFACE;
    
    // 原生窗口
    std::shared_ptr<RohyPlayerNativeWindow> nativeWindow_;
    
    // 同步锁
    std::mutex mutex_;
};

#endif //ROHYPLAYER_ROHY_PLAYER_H

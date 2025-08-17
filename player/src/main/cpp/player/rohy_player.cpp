#include "rohy_player.h"
#include "decoder/video/ffmpeg_video_decoder.h"
#include <cstdint>
#include <hilog/log.h>

RohyPlayer::RohyPlayer(const std::string& windowId) : windowId_(windowId) {
    nativeWindow_ = RohyPlayerWindowManager::getInstance()->getNativeXComponent(windowId_);
}

RohyPlayer::~RohyPlayer() {
    stop();
    cleanup();
}

bool RohyPlayer::load(const std::string& filePath) {
    // 创建解码器实例
    videoDecoder_ = std::make_unique<FFmpegVideoDecoder>();
    if (!videoDecoder_->open(filePath)) {
        return false;
    }
    
    // 音频解码器初始化（类似实现）
    // audioDecoder_ = std::make_unique<FFmpegAudioDecoder>();
    // if (!audioDecoder_->open(filePath)) { ... }
    
    return true;
}

void RohyPlayer::play() {
    if (isPlaying_) 
        return;
    
    isPlaying_ = true;
    stopRequested_ = false;
    
    // 启动渲染线程
    renderThread_ = std::thread(&RohyPlayer::renderLoop, this);
}

void RohyPlayer::pause() {
    isPlaying_ = false;
}

void RohyPlayer::stop() {
    stopRequested_ = true;
    if (renderThread_.joinable()) {
        renderThread_.join();
    }
    isPlaying_ = false;
    
    // 关闭解码器
    if (videoDecoder_) videoDecoder_->close();
    // if (audioDecoder_) audioDecoder_->close();
}

void RohyPlayer::renderLoop() {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: enter render loop");
    if (!initEGL()) {
        return;
    }
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: inited egl");
    
    // 创建OpenGL纹理
    GLuint texture;
    glGenTextures(1, &texture);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: gened texture");
    glBindTexture(GL_TEXTURE_2D, texture);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: bind texture");
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: min filter done");
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: mag filter done");
    
    while (true) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: looping");
        if (isPlaying_) {
            std::lock_guard<std::mutex> lock(mutex_);
            this->renderFrame(texture);
        } else {
            usleep(10000); // 暂停时休眠10ms
        }
    }
    
    // 清理OpenGL资源
    glDeleteTextures(1, &texture);
    
    // 释放EGL资源
    eglMakeCurrent(eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroySurface(eglDisplay_, eglSurface_);
    eglDestroyContext(eglDisplay_, eglContext_);
    eglTerminate(eglDisplay_);
}

bool RohyPlayer::initEGL() {
    // 获取原生窗口
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: initing egl");
    if (!nativeWindow_->nativeWindow) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: native window not found");
        return false;
    }
    
    // 初始化EGL
    eglDisplay_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: get default display");
    if (eglDisplay_ == EGL_NO_DISPLAY) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: no display");
        return false;
    }
    
    if (eglInitialize(eglDisplay_, nullptr, nullptr) != EGL_TRUE) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: failed to initalize egl with dispaly");
        return false;
    }
    
    // 配置属性
    const EGLint configAttribs[] = {
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_DEPTH_SIZE, 0,
        EGL_STENCIL_SIZE, 0,
        EGL_NONE
    };
    
    EGLConfig config;
    EGLint numConfigs;
    if (eglChooseConfig(eglDisplay_, configAttribs, &config, 1, &numConfigs) != EGL_TRUE) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: failed to choose egl config");
        return false;
    }
    
    // 创建EGL上下文
    const EGLint contextAttribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE
    };
    eglContext_ = eglCreateContext(eglDisplay_, config, EGL_NO_CONTEXT, contextAttribs);
    if (eglContext_ == EGL_NO_CONTEXT) {
         OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: failed to create egl context");
        return false;
    }
    
    // 创建EGL表面
    eglSurface_ = eglCreateWindowSurface(
        eglDisplay_, config, (EGLNativeWindowType) nativeWindow_->nativeWindow, 
        nullptr
    );
    if (eglSurface_ == EGL_NO_SURFACE) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: failed to create egl surface");
        return false;
    }
    
    // 关联上下文
    if (eglMakeCurrent(eglDisplay_, eglSurface_, eglSurface_, eglContext_) != EGL_TRUE) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: failed to make egl current");
        return false;
    }
    
    // 设置视口
    uint64_t width, height;
    OH_NativeXComponent_GetXComponentSize(nativeWindow_->nativeXComponent, nativeWindow_->nativeWindow, &width, &height);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: got native component size");
    glViewport(0, 0, width, height);
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: set viewport");
    
    return true;
}

void RohyPlayer::renderFrame(GLuint texture) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "RohyPlayer_Test", "FUCK: rendering frame");
    uint8_t* frameData = nullptr;
    int width, height, linesize;
    
    if (videoDecoder_->getNextFrame(&frameData, &width, &height, &linesize)) {
        // 上传纹理数据
        glBindTexture(GL_TEXTURE_2D, texture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 
                    0, GL_RGBA, GL_UNSIGNED_BYTE, frameData);
        
        // 清除屏幕
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // 渲染纹理（这里使用简单的全屏四边形）
        // 实际应用中应使用适当的着色器和顶点数据
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // 交换缓冲区
        eglSwapBuffers(eglDisplay_, eglSurface_);
    }
}

void RohyPlayer::cleanup() {
    if (videoDecoder_)
        videoDecoder_->close();
    // if (audioDecoder_) audioDecoder_->close();
}
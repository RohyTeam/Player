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
#include "player/renderer/rohy_player_opengl_renderer.h"
#include "rohy_player_window_manager.h"
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <fstream>
#include <unistd.h>

class RohyPlayer {
public:
    RohyPlayer();
    ~RohyPlayer();
    void init(const std::string& windowId);
private:
    std::string _windowId;
    std::shared_ptr<RohyPlayerNativeWindow> _nativeWindow;
    std::shared_ptr<OpenGLRenderer> renderer;
};

#endif //ROHYPLAYER_ROHY_PLAYER_H

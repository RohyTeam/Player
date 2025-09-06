#include "rohy_player.h"
#include "decoder/video/ffmpeg_video_decoder.h"
#include <cstdint>
#include <hilog/log.h>

RohyPlayer::RohyPlayer() {
    this->renderer = std::make_shared<OpenGLRenderer>();
}

RohyPlayer::~RohyPlayer() {
    this->renderer->release();
}

void RohyPlayer::init(const std::string& windowId) {
    this->_windowId = windowId;
    this->_nativeWindow = RohyPlayerWindowManager::getInstance()->getNativeXComponent(windowId);
    this->renderer->initEGL(this->_nativeWindow);
}
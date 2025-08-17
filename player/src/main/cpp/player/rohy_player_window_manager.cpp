#include "rohy_player_window_manager.h"

RohyPlayerWindowManager *RohyPlayerWindowManager::instance_{nullptr};
std::once_flag RohyPlayerWindowManager::flag_;

void RohyPlayerWindowManager::addNativeXComponent(
    std::shared_ptr<RohyPlayerNativeWindow> &window) {
  std::unique_lock<std::mutex> _(window_mutex);
  windows_[window->id] = window;
}

std::shared_ptr<RohyPlayerNativeWindow> RohyPlayerWindowManager::getNativeXComponent(const std::string &windowId) {
  std::unique_lock<std::mutex> _(window_mutex);
  auto it = windows_.find(windowId);
  if (it == windows_.end()) {
    return nullptr;
  }
  return it->second;
}

void RohyPlayerWindowManager::removeNativeXComponent(const std::string &windowId) {
  std::unique_lock<std::mutex> _(window_mutex);
  windows_.erase(windowId);
}

RohyPlayerWindowManager::~RohyPlayerWindowManager() {
  std::unique_lock<std::mutex> _(window_mutex);
  windows_.clear();
}

RohyPlayerWindowManager::RohyPlayerWindowManager() {}

RohyPlayerWindowManager *RohyPlayerWindowManager::getInstance() {
  std::call_once(flag_, []() { instance_ = new RohyPlayerWindowManager(); });
  return instance_;
}
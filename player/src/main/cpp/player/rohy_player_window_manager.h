#ifndef ROHYPLAYER_ROHY_PLAYER_WINDOW_MANAGER_H
#define ROHYPLAYER_ROHY_PLAYER_WINDOW_MANAGER_H

#include <map>
#include <mutex>
#include <string>
#include "ace/xcomponent/native_interface_xcomponent.h"

struct RohyPlayerNativeWindow {
  std::string id;
  OH_NativeXComponent *nativeXComponent{nullptr};
  void *nativeWindow{nullptr};
};

class RohyPlayerWindowManager {
public:
    void addNativeXComponent(std::shared_ptr<RohyPlayerNativeWindow> &component);
    std::shared_ptr<RohyPlayerNativeWindow> getNativeXComponent(const std::string &windowId);
    void removeNativeXComponent(const std::string &windowId);
    
    ~RohyPlayerWindowManager();
    
    static RohyPlayerWindowManager *getInstance();
private:
    RohyPlayerWindowManager();
    
    std::map<std::string, std::shared_ptr<RohyPlayerNativeWindow>> windows_;
    std::mutex window_mutex;
    
    static std::once_flag flag_;
    static RohyPlayerWindowManager *instance_;
};


#endif //ROHYPLAYER_ROHY_PLAYER_WINDOW_MANAGER_H

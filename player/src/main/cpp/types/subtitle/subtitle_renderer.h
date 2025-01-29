#ifndef ROHYPLAYER_SUBTITLE_RENDERER_H
#define ROHYPLAYER_SUBTITLE_RENDERER_H

#include <cstdint>
#include <unordered_map>
#include <native_window/external_window.h>

namespace RohyPlayer {

class SubtitleRenderer {
    
public:
    static std::unordered_map<uint64_t, OHNativeWindow*> nativeWindows;
    static void CreateNativeWindow(uint64_t surfaceId);
    static void DestroyNativeWindow(uint64_t surfaceId);
    static void StartRendering();
};

}

#endif //ROHYPLAYER_SUBTITLE_RENDERER_H

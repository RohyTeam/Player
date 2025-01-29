#include "subtitle_renderer.h"

namespace RohyPlayer {

void SubtitleRenderer::CreateNativeWindow(uint64_t surfaceId) {
    OHNativeWindow* nativeWindow;
    if (OH_NativeWindow_CreateNativeWindowFromSurfaceId(surfaceId, &nativeWindow) == 0) {
        SubtitleRenderer::nativeWindows[surfaceId] = nativeWindow;
    }
}

void SubtitleRenderer::StartRendering() {
    
}

void SubtitleRenderer::DestroyNativeWindow(uint64_t surfaceId) {
    SubtitleRenderer::nativeWindows.erase(surfaceId);
}

}
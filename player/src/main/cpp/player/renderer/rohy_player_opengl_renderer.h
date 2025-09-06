#ifndef ROHYPLAYER_ROHY_PLAYER_OPENGL_RENDERER_H
#define ROHYPLAYER_ROHY_PLAYER_OPENGL_RENDERER_H

#include "player/rohy_player_window_manager.h"
#include <EGL/egl.h>

class OpenGLRenderer {
public:
    OpenGLRenderer();
    ~OpenGLRenderer();
    
    void initEGL(std::shared_ptr<RohyPlayerNativeWindow> native_window);
    void release();
    
private:
    std::shared_ptr<RohyPlayerNativeWindow> _native_window;
    
    EGLDisplay _display;
    EGLContext _context;
    EGLSurface _surface;
};

#endif //ROHYPLAYER_ROHY_PLAYER_OPENGL_RENDERER_H

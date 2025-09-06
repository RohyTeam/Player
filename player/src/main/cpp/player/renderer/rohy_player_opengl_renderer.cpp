#include "rohy_player_opengl_renderer.h"
#include "utils/rohy_logger.h"

OpenGLRenderer::OpenGLRenderer() {
}

OpenGLRenderer::~OpenGLRenderer() {
    this->_native_window = nullptr;
    if (this->_display != nullptr) {
        if (this->_context != nullptr)
            eglDestroyContext(this->_display, this->_context);
        if (this->_surface != nullptr)
            eglDestroySurface(this->_display, this->_surface);
        eglTerminate(this->_display);
    }
}

void OpenGLRenderer::initEGL(std::shared_ptr<RohyPlayerNativeWindow> native_window) {
    this->_native_window = native_window;
    EGLConfig config;
    EGLint numConfigs;
    
    this->_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (this->_display == EGL_NO_DISPLAY) {
        ROHY_ERROR("OpenGLRenderer", "Failed to get egl display");
        return;
    }

    if (!eglInitialize(this->_display, nullptr, nullptr)) {
        ROHY_ERROR("OpenGLRenderer", "Failed to initialize egl display");
        return;
    }
    
    EGLint attributes[] = {
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_NONE
    };

    if (!eglChooseConfig(this->_display, attributes, &config, 1, &numConfigs)) {
        ROHY_ERROR("OpenGLRenderer", "Failed to choose egl config");
        return;
    }
    
    EGLint contextAttributes[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,
        EGL_NONE
    };
    
    this->_surface = eglCreateWindowSurface(this->_display, config, (EGLNativeWindowType) this->_native_window->nativeWindow, contextAttributes);
        
    if (this->_surface == EGL_NO_SURFACE) {
        switch (eglGetError()) {
            case EGL_BAD_MATCH:
                ROHY_ERROR("OpenGLRenderer", "EGL_BAD_MATCH: Window and egl config are not compatible");
                break;
            case EGL_BAD_CONFIG:
                ROHY_ERROR("OpenGLRenderer", "EGL_BAD_CONFIG: egl config not valid");
                return;
            case EGL_BAD_NATIVE_WINDOW:
                ROHY_ERROR("OpenGLRenderer", "EGL_BAD_NATIVE_WINDOW: native window not valid");
                return;
            case EGL_BAD_ALLOC:
                ROHY_ERROR("OpenGLRenderer", "EGL_BAD_ALLOC: not enough resource");
                return;
            default:
                ROHY_ERROR("OpenGLRenderer", "EGL_ERROR: unknown egl error");
                return;;
        }
    }
    
    this->_context = eglCreateContext(this->_display, config, EGL_NO_CONTEXT, contextAttributes);
    
    if (this->_context == EGL_NO_CONTEXT) {
        ROHY_ERROR("OpenGLRenderer", "Failed to create egl context");
        return;
    }
    
    if (!eglMakeCurrent(this->_display, this->_surface, this->_surface, this->_context)) {
        ROHY_ERROR("OpenGLRenderer", "Failed to make egl current");
        return;
    }
}

void OpenGLRenderer::release() {
    this->_native_window = nullptr;
    if (this->_display != nullptr) {
        if (this->_context != nullptr)
            eglDestroyContext(this->_display, this->_context);
        if (this->_surface != nullptr)
            eglDestroySurface(this->_display, this->_surface);
        eglTerminate(this->_display);
    }
}
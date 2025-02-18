//
// Created on 2025/2/18.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "subtitle/subtitle_napi.h"
#include "hilog/log.h"
#include "utils/napi_utils.h"

const char* VERTEX_SHADER = R"(
attribute vec4 a_position;
attribute vec2 a_texCoord;
varying vec2 v_texCoord;
void main() {
    gl_Position = a_position;
    v_texCoord = a_texCoord;
})";

const char* FRAGMENT_SHADER = R"(
precision mediump float;
varying vec2 v_texCoord;
uniform sampler2D s_texture;
void main() {
    // gl_FragColor = texture2D(s_texture, v_texCoord);
    vec4 texColor = texture2D(s_texture, v_texCoord);
    gl_FragColor = vec4(texColor.rgb, texColor.a); // 确保Alpha生效
})";

void SubtitleRenderer::initASS(char *buf, size_t bufsize) {
    m_assLibrary = ass_library_init();
    if (!m_assLibrary) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to init ass library");
        return;
    }

    m_assRenderer = ass_renderer_init(m_assLibrary);
    if (!m_assRenderer) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to init ass renderer");
        return;
    }
    ass_set_frame_size(m_assRenderer, SubtitleRenderer::GetInstance()->width_, SubtitleRenderer::GetInstance()->height_);
    // ass_set_fonts(m_assRenderer, "/data/storage/el2/base/haps/player/files/fallback.ttf", "HarmonyOS Sans SC", 1, nullptr, 0);
    
    // 添加字体遍历逻辑
    if (!fonts_.empty()) {
        for (const auto& [fontName, fontData] : fonts_) {
            OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK!: added font with name %{public}s", fontName.c_str());
            ass_add_font(m_assLibrary, fontName.c_str(),
                                         fontData.fontData, fontData.fontSize);
        }
        ass_set_fonts(m_assRenderer, nullptr, "HarmonyOS Sans SC", 1, nullptr, 1);
    } else {
        OH_LOG_Print(LOG_APP, LOG_WARN, 0, "FontAdd", "No custom fonts available");
    }
    
    // char* url = new char[path.size() + 1];
    // std::strcpy(url, path.c_str());
    // OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK!: path is %{public}s", url);
    // m_assTrack = ass_read_file(m_assLibrary, url, nullptr);
    m_assTrack = ass_read_memory(m_assLibrary, buf, bufsize, nullptr);
    if (m_assTrack == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to read subtitle file");
        return;
    }
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "--------------------\n"
                                                    "|| Loaded Subtitle Info ||\n"
                                                    "Language: %{public}s\n"
                                                    "Track type: %{public}d\n"
                                                    "Name: %{public}s\n"
                                                    "--------------------\n",
        m_assTrack->Language, m_assTrack->track_type, m_assTrack->name
    );
}

void SubtitleRenderer::initEGL() {
    EGLDisplay display;
    EGLConfig config;
    EGLContext context;
    EGLSurface surface;
    EGLint numConfigs;
    EGLint majorVersion;
    EGLint minorVersion;

    display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    
    if (display == EGL_NO_DISPLAY) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to get egl display");
    }

    if (!eglInitialize(display, &majorVersion, &minorVersion)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to initialize eg;");
    }

    EGLint attribs[] = {
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_ALPHA_SIZE, 8,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_NONE
    };
    if (!eglChooseConfig(display, attribs, &config, 1, &numConfigs)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to choose egl config");
    }

    EGLint contextAttribs[] = {
        EGL_CONTEXT_CLIENT_VERSION, 3,
        EGL_NONE
    };
    
    if (SubtitleRenderer::GetInstance()->nativeWindow_ == nullptr) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: CANNOT FIND NATIVE WINDOW");
    }

    surface = eglCreateWindowSurface(display, config, (EGLNativeWindowType) SubtitleRenderer::GetInstance()->nativeWindow_, NULL);
    
    if (surface == EGL_NO_SURFACE) {
    switch (eglGetError()) {
        case EGL_BAD_MATCH:
            // 检查窗口和 EGLConfig 属性以确定兼容性，或者验证 EGLConfig 是否支持渲染到窗口
                OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: EGL_BAD_MATCH");
            break;
        case EGL_BAD_CONFIG:
            // 验证提供的 EGLConfig 是否有效
                OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: EGL_BAD_CONFIG");
            break;
        case EGL_BAD_NATIVE_WINDOW:
            // 验证提供的 EGLNativeWindow 是否有效
                OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: EGL_BAD_NATIVE_WINDOW");
            break;
        case EGL_BAD_ALLOC:
            // 资源不足；处理并恢复
                OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: EGL_BAD_ALLOC");
            break;
        default:
            // 处理任何其他错误
                OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: SURFACE OTHER ERROR");
            break;
        }
    }
    context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttribs);
    SubtitleRenderer::GetInstance()->eglDisplay_ = display;
    SubtitleRenderer::GetInstance()->eglSurface_ = surface;
    SubtitleRenderer::GetInstance()->eglContext_ = context;
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    if (!eglMakeCurrent(display, surface, surface, context)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCKERROR!: failed to make egl current");
    }
}

void SubtitleRenderer::compileShader() {
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &VERTEX_SHADER, nullptr);
    glCompileShader(vertexShader);

    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &FRAGMENT_SHADER, nullptr);
    glCompileShader(fragmentShader);

    m_program = glCreateProgram();
    glAttachShader(m_program, vertexShader);
    glAttachShader(m_program, fragmentShader);
    glLinkProgram(m_program);

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    m_positionLoc = glGetAttribLocation(m_program, "a_position");
    m_texCoordLoc = glGetAttribLocation(m_program, "a_texCoord");
    m_samplerLoc = glGetUniformLocation(m_program, "s_texture");
}

void SubtitleRenderer::renderImage(ASS_Image* img) {
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    std::vector<uint8_t> rgba(img->w * img->h * 4);
    for (int i = 0; i < img->w * img->h; ++i) {
        rgba[i*4+3] = img->bitmap[i];
        rgba[i*4+0] = rgba[i*4+1] = rgba[i*4+2] = 255;
    }

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, img->w, img->h, 
                0, GL_RGBA, GL_UNSIGNED_BYTE, rgba.data());
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    const GLfloat vertices[] = {
        -1.0f, -1.0f, 0.0f,
         1.0f, -1.0f, 0.0f,
        -1.0f,  1.0f, 0.0f,
         1.0f,  1.0f, 0.0f
    };

    const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f
    };

    glVertexAttribPointer(m_positionLoc, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(m_texCoordLoc, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
    glEnableVertexAttribArray(m_positionLoc);
    glEnableVertexAttribArray(m_texCoordLoc);

    glActiveTexture(GL_TEXTURE0);
    glUniform1i(m_samplerLoc, 0);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDeleteTextures(1, &texture);
}

void SubtitleRenderer::release() {
    if (m_assTrack) ass_free_track(m_assTrack);
    if (m_assRenderer) ass_renderer_done(m_assRenderer);
    if (m_assLibrary) ass_library_done(m_assLibrary);

    if (this->eglDisplay_ != EGL_NO_DISPLAY) {
        eglMakeCurrent(this->eglDisplay_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (this->eglContext_) eglDestroyContext(this->eglDisplay_, this->eglContext_);
        if (this->eglSurface_) eglDestroySurface(this->eglDisplay_, this->eglSurface_);
        eglTerminate(this->eglDisplay_);
    }

    if (m_program) {
        glDeleteProgram(m_program);
    }
}

napi_value SubtitleRenderer::Init(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK! init");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    void* data;
    size_t length;
    napi_get_buffer_info(env, args[0], &data, &length);
    
    SubtitleRenderer* instance = SubtitleRenderer::GetInstance();
    
    instance->initEGL();
    instance->compileShader();
    instance->initASS((char*) data, length);
    
    return nullptr;
}

napi_value SubtitleRenderer::AddFont(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK! add font");
    
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    std::string fontName;
    NapiUtils::JsValueToString(env, args[0], 2048, fontName);
    
    void* data;
    size_t length;
    napi_get_buffer_info(env, args[1], &data, &length);
    
    FontData fontData;
    fontData.fontData = (char*) data;
    fontData.fontSize = length;
    
    SubtitleRenderer::GetInstance()->fonts_[fontName] = fontData;
    
    return nullptr;
}

napi_value SubtitleRenderer::Render(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK! render");
    
    SubtitleRenderer* instance = SubtitleRenderer::GetInstance();
    
    glViewport(0, 0, instance->width_, instance->height_);
    
    if (!instance->eglContext_ || !instance->m_assRenderer || !instance->m_assTrack) 
        return nullptr;
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    int64_t time, width, height;
    napi_get_value_int64(env, args[0], &time);
    napi_get_value_int64(env, args[1], &width);
    napi_get_value_int64(env, args[2], &height);
    
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(instance->m_program);
    glEnableVertexAttribArray(instance->m_positionLoc);
    glEnableVertexAttribArray(instance->m_texCoordLoc);
    
    ASS_Image* img = ass_render_frame(instance->m_assRenderer, instance->m_assTrack, time, nullptr);
    while (img) {
        instance->renderImage(img);
        img = img->next;
    }

    eglSwapBuffers(instance->eglDisplay_, instance->eglSurface_);
    
    return nullptr;
}

napi_value SubtitleRenderer::Release(napi_env env, napi_callback_info info) {
    SubtitleRenderer::GetInstance()->release();
    return nullptr;
}

void OnSurfaceCreatedCB(OH_NativeXComponent* component, void* window)
{
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK!: Created surface");
    
    OHNativeWindow* nativeWindow = (NativeWindow*) (window);
    
    uint64_t width, height;
    OH_NativeXComponent_GetXComponentSize(component, nativeWindow, &width, &height);
    
    SubtitleRenderer::GetInstance()->nativeXComponent_ = component;
    SubtitleRenderer::GetInstance()->nativeWindow_ = nativeWindow;
    SubtitleRenderer::GetInstance()->width_ = width;
    SubtitleRenderer::GetInstance()->height_ = height;
}

void OnSurfaceChangedCB(OH_NativeXComponent* component, void* window)
{
}

void OnSurfaceDestroyedCB(OH_NativeXComponent* component, void* window)
{
}

SubtitleRenderer* SubtitleRenderer::GetInstance()
{
    static SubtitleRenderer subtitleRender;
    return &subtitleRender;
}

bool SubtitleRenderer::Export(napi_env env, napi_value exports)
{
    napi_status status;

    napi_property_descriptor desc[] = {
        { "Subtitle_Init", nullptr, SubtitleRenderer::Init, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "Subtitle_AddFont", nullptr, SubtitleRenderer::AddFont, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "Subtitle_Render", nullptr, SubtitleRenderer::Render, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "Subtitle_Release", nullptr, SubtitleRenderer::Release, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    callback_.OnSurfaceCreated = OnSurfaceCreatedCB;
    callback_.OnSurfaceChanged = OnSurfaceChangedCB;
    callback_.OnSurfaceDestroyed = OnSurfaceDestroyedCB;
    
    napi_value exportInstance = nullptr;
    OH_NativeXComponent *nativeXComponent = nullptr;
    int32_t ret;
    char idStr[OH_XCOMPONENT_ID_LEN_MAX + 1] = {};
    uint64_t idSize = OH_XCOMPONENT_ID_LEN_MAX + 1;

    status = napi_get_named_property(env, exports, OH_NATIVE_XCOMPONENT_OBJ, &exportInstance);
    if (status != napi_ok) {
        return false;
    }

    status = napi_unwrap(env, exportInstance, reinterpret_cast<void**>(&nativeXComponent));
    if (status != napi_ok) {
        return false;
    }

    ret = OH_NativeXComponent_GetXComponentId(nativeXComponent, idStr, &idSize);
    if (ret != OH_NATIVEXCOMPONENT_RESULT_SUCCESS) {
        return false;
    }
    OH_NativeXComponent_RegisterCallback(nativeXComponent, &callback_);
        
    return true;
}
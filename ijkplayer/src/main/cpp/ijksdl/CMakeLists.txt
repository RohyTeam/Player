# the minimum version of CMake.
cmake_minimum_required(VERSION 3.4.1)

project("ijkplayer")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion")

add_definitions(-DOHOS_PLATFORM)

add_library(ijksdl  SHARED    ijksdl_aout.c
                              ijksdl_audio.c
                              ijksdl_egl.c
                              ijksdl_error.c
                              ijksdl_mutex.c
                              ijksdl_stdinc.c
                              ijksdl_thread.c
                              ijksdl_timer.c
                              ijksdl_vout.c
                              ijksdl_extra_log.c
                              video/gles2/color.c
                              video/gles2/common.c
                              video/gles2/renderer.c
                              video/gles2/renderer_rgb.c
                              video/gles2/renderer_yuv420p.c
                              video/gles2/renderer_yuv444p10le.c
                              video/gles2/shader.c
                              video/gles2/fsh/rgb.fsh.c
                              video/gles2/fsh/yuv420p.fsh.c
                              video/gles2/fsh/yuv444p10le.fsh.c
                              video/gles2/vsh/mvp.vsh.c
                              video/ijksdl_vout_android_nativewindow.c
                              video/ijksdl_vout_android_surface.c
                              ffmpeg/ijksdl_vout_overlay_ffmpeg.c
                              ffmpeg/abi_all/image_convert.c
                              audio/ijksdl_aout_android_opensles.c
                              dummy/ijksdl_vout_dummy.c
                              ${CMAKE_CURRENT_SOURCE_DIR}/../utils/ohoslog/ohos_log.cpp
                               )

add_library(yuv STATIC IMPORTED)
set_target_properties(yuv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libyuv-ijk/${OHOS_ARCH}/lib/libyuv.a)


#add_library(ijkOpenSLES SHARED IMPORTED)
#set_target_properties(ijkOpenSLES PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../../../../libs/${OHOS_ARCH}/libijkOpenSLES.so)


include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/ffmpeg/)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/ffmpeg/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openssl3/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/soundtouch/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libyuv-ijk/${OHOS_ARCH}/include)

target_link_directories(ijksdl PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/ffmpeg/${OHOS_ARCH}/lib
${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openssl3/${OHOS_ARCH}/lib ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/soundtouch/${OHOS_ARCH}/lib
${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libyuv-ijk/${OHOS_ARCH}/lib ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openh264/${OHOS_ARCH}/lib)

target_link_libraries(ijksdl yuv)
target_link_libraries(ijksdl EGL)
target_link_libraries(ijksdl GLESv3)
target_link_libraries(ijksdl hilog_ndk.z)
target_link_libraries(ijksdl native_window)
target_link_libraries(ijksdl z)
target_link_libraries(ijksdl avcodec)
target_link_libraries(ijksdl avfilter)
target_link_libraries(ijksdl avformat)
target_link_libraries(ijksdl avutil)
target_link_libraries(ijksdl swresample)
target_link_libraries(ijksdl swscale)
target_link_libraries(ijksdl avdevice)
target_link_libraries(ijksdl crypto)
target_link_libraries(ijksdl ssl)
target_link_libraries(ijksdl libohaudio.so)
target_link_libraries(ijksdl openh264)
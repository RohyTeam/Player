# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(RohyPlayerReborn)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion -Wl,-Bsymbolic")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-int-conversion -Wl,-Bsymbolic")

set(CMAKE_CXX_STANDARD 17)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}
                    ${CMAKE_CURRENT_SOURCE_DIR}/include
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fontconfig/${OHOS_ARCH}/include
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/ffmpeg
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/ffmpeg/${OHOS_ARCH}/include
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/freetype2/${OHOS_ARCH}/include
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libpng/${OHOS_ARCH}/include
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libass/${OHOS_ARCH}/include)

set(CMAKE_CXX_STANDARD 17)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

add_library(player SHARED napi_init.cpp utils/napi_utils.cpp)
target_link_libraries(player PUBLIC libace_napi.z.so)

add_library(rohy_subtitle SHARED subtitle/rohy_subtitle_napi.cpp
                            subtitle/rohy_subtitle_utils.cpp
                            subtitle/rohy_ass_subtitle_renderer.cpp
                            subtitle/rohy_pgs_subtitle_renderer.cpp
                            utils/napi_utils.cpp
                            subtitle/pgs/object_definition.cpp
                            subtitle/pgs/pgs_util.cpp
                            subtitle/pgs/palette_definition.cpp
                            subtitle/pgs/presentation_composition.cpp
                            subtitle/pgs/segment.cpp
                            subtitle/pgs/segment_data.cpp
                            subtitle/pgs/subtitle.cpp
                            subtitle/pgs/window_definition.cpp)

add_library(rohy_metadata SHARED metadata/rohy_metadata_napi.cpp metadata/rohy_metadata_getter.cpp metadata/rohy_metadata_exporter.cpp utils/napi_utils.cpp)

target_link_libraries(rohy_subtitle PUBLIC libace_napi.z.so libace_ndk.z.so libhilog_ndk.z.so libGLESv3.so libEGL.so libnative_window.so)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/ffmpeg/${OHOS_ARCH}/lib/libavformat.a)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/ffmpeg/${OHOS_ARCH}/lib/libavcodec.a)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libass/${OHOS_ARCH}/lib/libass.so.9)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libpng/${OHOS_ARCH}/lib/libpng16.so.16)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fontconfig/${OHOS_ARCH}/lib/libfontconfig.so)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fribidi/${OHOS_ARCH}/lib/libfribidi.so)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/freetype2/${OHOS_ARCH}/lib/libfreetype.a)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/harfbuzz/${OHOS_ARCH}/lib/libharfbuzz.so)
target_link_libraries(rohy_subtitle PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/zlib/${OHOS_ARCH}/lib/libz.so.1)

target_link_directories(rohy_metadata PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/ffmpeg/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/openssl3/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/openh264/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/openjpeg/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libiconv/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/lame/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libcodec2/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libkvazaar/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libvpx/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libopus/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x264/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x265/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/xz/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fontconfig/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fribidi/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/freetype2/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libbluray/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libass/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libxml2/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/harfbuzz/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libudfread/${OHOS_ARCH}/lib
 )

target_link_libraries(rohy_metadata ace_napi.z)
target_link_libraries(rohy_metadata ace_ndk.z)
target_link_libraries(rohy_metadata native_window)
target_link_libraries(rohy_metadata EGL)
target_link_libraries(rohy_metadata GLESv3)
target_link_libraries(rohy_metadata hilog_ndk.z)
target_link_libraries(rohy_metadata z)
target_link_libraries(rohy_metadata avcodec)
target_link_libraries(rohy_metadata avfilter)
target_link_libraries(rohy_metadata avformat)
target_link_libraries(rohy_metadata avutil)
target_link_libraries(rohy_metadata swresample)
target_link_libraries(rohy_metadata postproc)
target_link_libraries(rohy_metadata swscale)
target_link_libraries(rohy_metadata avdevice)
target_link_libraries(rohy_metadata crypto)
target_link_libraries(rohy_metadata ssl)
target_link_libraries(rohy_metadata libnative_media_codecbase.so)
target_link_libraries(rohy_metadata libnative_media_core.so)
target_link_libraries(rohy_metadata libnative_media_vdec.so)
target_link_libraries(rohy_metadata libnative_window.so)
target_link_libraries(rohy_metadata libnative_buffer.so)
target_link_libraries(rohy_metadata openh264)

target_link_libraries(rohy_metadata vpx)
target_link_libraries(rohy_metadata opus)
target_link_libraries(rohy_metadata fontconfig)
target_link_libraries(rohy_metadata freetype)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libudfread/${OHOS_ARCH}/lib/libudfread.so.0)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/harfbuzz/${OHOS_ARCH}/lib/libharfbuzz.so.0)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libxml2/${OHOS_ARCH}/lib/libxml2.so)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libass/${OHOS_ARCH}/lib/libass.so.9)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fontconfig/${OHOS_ARCH}/lib/libfontconfig.so.1)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fribidi/${OHOS_ARCH}/lib/libfribidi.so.0)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libbluray/${OHOS_ARCH}/lib/libbluray.so.2)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/xz/${OHOS_ARCH}/lib/liblzma.so.5)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/openjpeg/${OHOS_ARCH}/lib/libopenjp2.so.7)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libcodec2/${OHOS_ARCH}/lib/libcodec2.so.0.9)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/lame/${OHOS_ARCH}/lib/libmp3lame.so.0)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libkvazaar/${OHOS_ARCH}/lib/libkvazaar.so.7)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libiconv/${OHOS_ARCH}/lib/libiconv.so.2)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x264/${OHOS_ARCH}/lib/libx264.a)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x265/${OHOS_ARCH}/lib/libx265.so.215)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x265/${OHOS_ARCH}/lib/libx265.so)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x265/${OHOS_ARCH}/lib/libx265_main10.so)
target_link_libraries(rohy_metadata ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x265/${OHOS_ARCH}/lib/libx265_main12.so)

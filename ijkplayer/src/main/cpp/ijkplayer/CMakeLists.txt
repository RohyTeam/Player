# the minimum version of CMake.
cmake_minimum_required(VERSION 3.4.1)

project("ijkplayer")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion")

add_definitions(-DOHOS_PLATFORM)

add_library(ijkplayer  SHARED
                               ff_cmdutils.c
                               ff_ffplay.c
                               ff_ffpipeline.c
                               ff_ffpipenode.c
                               ijkmeta.c
                               ijkplayer.c
                               ijkplayer_android.c
                               pipeline/ffpipenode_ffplay_vdec.c
                               pipeline/ffpipeline_android.c
                               ijkavformat/allformats.c
                               ijkavformat/ijklivehook.c
                               ijkavformat/ijkio.c
                               ijkavformat/ijkiomanager.c
                               ijkavformat/ijkiocache.c
                               ijkavformat/ijkioffio.c
                                ijkavformat/ijkioprotocol.c
                                ijkavformat/ijkioapplication.c
                                ijkavformat/ijkiourlhook.c
                                ijkavformat/ijkasync.c
                                ijkavformat/ijkurlhook.c
                                ijkavformat/ijklongurl.c
                                ijkavformat/ijksegment.c
                                ijkavutil/ijkdict.c
                                ijkavutil/ijkutils.c
                                ijkavutil/ijkthreadpool.c
                                 ijkavutil/ijktree.c
                                 ijkavutil/ijkfifo.c
                                 ijkavutil/ijkstl.cpp
                                 ohos/ffpipenode_ohos_mediacodec_vdec.cpp
                                 ohos/ohos_video_decoder_data.cpp
                                 ohos/ohos_video_decoder_Info.cpp
                                 ohos/ohos_video_decoder.cpp
                                 record/ijkplayer_record.cpp
                                )


add_library(soundtouch STATIC IMPORTED)
set_target_properties(soundtouch PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/soundtouch/${OHOS_ARCH}/lib/libsoundtouch.a)

add_library(ijksdl_so SHARED IMPORTED)
set_target_properties(ijksdl_so PROPERTIES IMPORTED_LOCATION ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/libijksdl.so)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/ffmpeg/)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/ffmpeg/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openssl3/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/soundtouch/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libyuv-ijk/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libiconv/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/lame/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libcodec2/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openjpeg/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libvpx/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libopus/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libkvazaar/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x264/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x265/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/xz/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fontconfig/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fribidi/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libbluray/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/freetype2/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libass/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libxml2/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/harfbuzz/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libudfread/${OHOS_ARCH}/include)

target_link_directories(ijkplayer PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/ffmpeg/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openssl3/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openh264/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openjpeg/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libiconv/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/lame/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libcodec2/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libkvazaar/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libvpx/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libopus/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x264/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x265/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/xz/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fontconfig/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fribidi/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/freetype2/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libbluray/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libass/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libxml2/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/harfbuzz/${OHOS_ARCH}/lib
 ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libudfread/${OHOS_ARCH}/lib
 )

target_link_libraries(ijkplayer ijksdl_so)
target_link_libraries(ijkplayer EGL)
target_link_libraries(ijkplayer GLESv3)
target_link_libraries(ijkplayer hilog_ndk.z)
target_link_libraries(ijkplayer soundtouch)
target_link_libraries(ijkplayer z)
target_link_libraries(ijkplayer avcodec)
target_link_libraries(ijkplayer avfilter)
target_link_libraries(ijkplayer avformat)
target_link_libraries(ijkplayer avutil)
target_link_libraries(ijkplayer swresample)
target_link_libraries(ijkplayer postproc)
target_link_libraries(ijkplayer swscale)
target_link_libraries(ijkplayer avdevice)
target_link_libraries(ijkplayer crypto)
target_link_libraries(ijkplayer ssl)
target_link_libraries(ijkplayer libnative_media_codecbase.so)
target_link_libraries(ijkplayer libnative_media_core.so)
target_link_libraries(ijkplayer libnative_media_vdec.so)
target_link_libraries(ijkplayer libnative_window.so)
target_link_libraries(ijkplayer libnative_buffer.so)
target_link_libraries(ijkplayer openh264)

target_link_libraries(ijkplayer vpx)
target_link_libraries(ijkplayer opus)
target_link_libraries(ijkplayer fontconfig)
target_link_libraries(ijkplayer freetype)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libudfread/${OHOS_ARCH}/lib/libudfread.so.0)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/harfbuzz/${OHOS_ARCH}/lib/libharfbuzz.so.0)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libxml2/${OHOS_ARCH}/lib/libxml2.so)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libass/${OHOS_ARCH}/lib/libass.so.9)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fontconfig/${OHOS_ARCH}/lib/libfontconfig.so.1)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fribidi/${OHOS_ARCH}/lib/libfribidi.so.0)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libbluray/${OHOS_ARCH}/lib/libbluray.so.2)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/xz/${OHOS_ARCH}/lib/liblzma.so.5)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/openjpeg/${OHOS_ARCH}/lib/libopenjp2.so.7)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libcodec2/${OHOS_ARCH}/lib/libcodec2.so.0.9)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/lame/${OHOS_ARCH}/lib/libmp3lame.so.0)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libkvazaar/${OHOS_ARCH}/lib/libkvazaar.so.7)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libiconv/${OHOS_ARCH}/lib/libiconv.so.2)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x264/${OHOS_ARCH}/lib/libx264.a)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x265/${OHOS_ARCH}/lib/libx265.so.215)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x265/${OHOS_ARCH}/lib/libx265.so)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x265/${OHOS_ARCH}/lib/libx265_main10.so)
target_link_libraries(ijkplayer ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/x265/${OHOS_ARCH}/lib/libx265_main12.so)
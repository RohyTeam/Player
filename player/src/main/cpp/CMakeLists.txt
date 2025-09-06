# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(RohyPlayerReborn)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion -Wl,-Bsymbolic")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-int-conversion -Wl,-Bsymbolic")

set(THIRDPARTY_LIBRARY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty")
set(CMAKE_CXX_STANDARD 17)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}
                    ${CMAKE_CURRENT_SOURCE_DIR}/include
                    ${THIRDPARTY_LIBRARY_DIR}/avisynth/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/brotli/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/bzip2_1_0_8/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/davs2/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/fdk-aac/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/fontconfig/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/freetype2/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/fribidi/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/harfbuzz/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/jbigkit/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/json-c/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/kvazaar/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/lame/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/lcevc/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/lcms2/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libaom/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libass/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libbluray/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libdav1d/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libdeflate/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libiconv/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libjpeg-turbo/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libogg/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libpng/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libudfread/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libunibreak/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libvpx/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libxml2/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/libzip/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/openh264/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/openjpeg/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/openssl/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/opus/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/rav1e/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/speex/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/tiff/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/uavs3d/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/vvenc/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/x264/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/xavs2/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/xvidcore/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/xz/${OHOS_ARCH}/include
                    ${THIRDPARTY_LIBRARY_DIR}/zstd_1_5_6/${OHOS_ARCH}/include)

set(CMAKE_CXX_STANDARD 17)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

add_library(rohy_player SHARED player/rohy_player_napi.cpp
                            player/rohy_player.cpp
                            player/rohy_player_window_manager.cpp
                            player/decoder/video/ffmpeg_video_decoder.cpp
                            player/demuxer/ffmpeg_demuxer.cpp
                            player/renderer/rohy_player_opengl_renderer.cpp
                            utils/napi_utils.cpp)

add_library(rohy_subtitle SHARED subtitle/rohy_subtitle_napi.cpp
                            subtitle/rohy_subtitle_utils.cpp
                            subtitle/rohy_ass_subtitle_renderer.cpp
                            subtitle/rohy_pgs_subtitle_renderer.cpp
                            subtitle/sendable_rohy_pgs_subtitle_renderer.cpp
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

target_link_libraries(rohy_subtitle libace_napi.z.so libace_ndk.z.so libhilog_ndk.z.so libGLESv3.so libEGL.so libnative_window.so)
target_link_libraries(rohy_subtitle ${THIRDPARTY_LIBRARY_DIR}/libass/${OHOS_ARCH}/lib/libass.so.9)
target_link_libraries(rohy_subtitle ${THIRDPARTY_LIBRARY_DIR}/libpng/${OHOS_ARCH}/lib/libpng16.so.16)
target_link_libraries(rohy_subtitle ${THIRDPARTY_LIBRARY_DIR}/fontconfig/${OHOS_ARCH}/lib/libfontconfig.so)
target_link_libraries(rohy_subtitle ${THIRDPARTY_LIBRARY_DIR}/fribidi/${OHOS_ARCH}/lib/libfribidi.so)
target_link_libraries(rohy_subtitle ${THIRDPARTY_LIBRARY_DIR}/freetype2/${OHOS_ARCH}/lib/libfreetype.a)
target_link_libraries(rohy_subtitle ${THIRDPARTY_LIBRARY_DIR}/harfbuzz/${OHOS_ARCH}/lib/libharfbuzz.so)
target_link_libraries(rohy_subtitle ${THIRDPARTY_LIBRARY_DIR}/zlib_1_3_1/${OHOS_ARCH}/lib/libz.so.1)

target_link_libraries(rohy_metadata ace_napi.z)
target_link_libraries(rohy_metadata ace_ndk.z)
target_link_libraries(rohy_metadata native_window)
target_link_libraries(rohy_metadata EGL)
target_link_libraries(rohy_metadata GLESv3)
target_link_libraries(rohy_metadata hilog_ndk.z)
target_link_libraries(rohy_metadata z)
target_link_libraries(rohy_metadata libnative_media_codecbase.so)
target_link_libraries(rohy_metadata libnative_media_core.so)
target_link_libraries(rohy_metadata libnative_media_vdec.so)
target_link_libraries(rohy_metadata libnative_window.so)
target_link_libraries(rohy_metadata libnative_buffer.so)

target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/avisynth/${OHOS_ARCH}/lib/libavisynth.so.11)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/brotli/${OHOS_ARCH}/lib/libbrotlicommon-static.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/brotli/${OHOS_ARCH}/lib/libbrotlidec-static.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/brotli/${OHOS_ARCH}/lib/libbrotlienc-static.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/bzip2_1_0_8/${OHOS_ARCH}/lib/libbz2.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/davs2/${OHOS_ARCH}/lib/libdavs2.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/fdk-aac/${OHOS_ARCH}/lib/libfdk-aac.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavcodec.so.61)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavdevice.so.61)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavfilter.so.10)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavformat.so.61)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavutil.so.59)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libpostproc.so.58)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libswresample.so.5)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libswscale.so.8)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/fontconfig/${OHOS_ARCH}/lib/libfontconfig.so.1)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/freetype2/${OHOS_ARCH}/lib/libfreetype.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/fribidi/${OHOS_ARCH}/lib/libfribidi.so.0)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/harfbuzz/${OHOS_ARCH}/lib/libharfbuzz.so.0)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/jbigkit/${OHOS_ARCH}/lib/libjbig.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/json-c/${OHOS_ARCH}/lib/libjson-c.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/kvazaar/${OHOS_ARCH}/lib/libkvazaar.so.7)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/lame/${OHOS_ARCH}/lib/libmp3lame.so.0)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/lcevc/${OHOS_ARCH}/lib/liblcevc_dec_api.so)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/lcevc/${OHOS_ARCH}/lib/liblcevc_dec_core.so)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/lcms2/${OHOS_ARCH}/lib/liblcms2.so.2)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libaom/${OHOS_ARCH}/lib/libaom.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libass/${OHOS_ARCH}/lib/libass.so.9)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libbluray/${OHOS_ARCH}/lib/libbluray.so.3)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libdav1d/${OHOS_ARCH}/lib/libdav1d.so.7)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libdeflate/${OHOS_ARCH}/lib/libdeflate.so.0)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libiconv/${OHOS_ARCH}/lib/libcharset.so.1)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libiconv/${OHOS_ARCH}/lib/libiconv.so.2)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libjpeg-turbo/${OHOS_ARCH}/lib/libjpeg.so.62)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libjpeg-turbo/${OHOS_ARCH}/lib/libturbojpeg.so.0)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libogg/${OHOS_ARCH}/lib/libogg.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libpng/${OHOS_ARCH}/lib/libpng16.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libudfread/${OHOS_ARCH}/lib/libudfread.so.3)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libunibreak/${OHOS_ARCH}/lib/libunibreak.so.6)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libvpx/${OHOS_ARCH}/lib/libvpx.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libsharpyuv.so.0)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libwebp.so.7)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libwebpdecoder.so.3)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libwebpdemux.so.2)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libwebpmux.so.3)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libxml2/${OHOS_ARCH}/lib/libxml2.so.2)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/libzip/${OHOS_ARCH}/lib/libzip.so.5)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/openh264/${OHOS_ARCH}/lib/libopenh264.so.7)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/openjpeg/${OHOS_ARCH}/lib/libopenjp2.so.7)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/openssl/${OHOS_ARCH}/lib/libcrypto.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/openssl/${OHOS_ARCH}/lib/libssl.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/opus/${OHOS_ARCH}/lib/libopus.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/rav1e/${OHOS_ARCH}/lib/librav1e.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/speex/${OHOS_ARCH}/lib/libspeex.so.1)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/tiff/${OHOS_ARCH}/lib/libtiff.so.6)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/tiff/${OHOS_ARCH}/lib/libtiffxx.so.6)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/uavs3d/${OHOS_ARCH}/lib/libuavs3d.so)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/vvenc/${OHOS_ARCH}/lib/libvvenc.so.1.13)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/x264/${OHOS_ARCH}/lib/libx264.so.164)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/lib/libx265.so)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/lib/libx265.so.215)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/lib/libx265_main10.so)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/lib/libx265_main12.so)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/xavs2/${OHOS_ARCH}/lib/libxavs2.a)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/xvidcore/${OHOS_ARCH}/lib/libxvidcore.so.4)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/xz/${OHOS_ARCH}/lib/liblzma.so.5)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/zlib_1_3_1/${OHOS_ARCH}/lib/libz.so.1)
target_link_libraries(rohy_metadata ${THIRDPARTY_LIBRARY_DIR}/zstd_1_5_6/${OHOS_ARCH}/lib/libzstd.so.1)

target_link_libraries(rohy_player ace_napi.z)
target_link_libraries(rohy_player hilog_ndk.z)
target_link_libraries(rohy_player native_media_core)
target_link_libraries(rohy_player native_media_adec)
target_link_libraries(rohy_player native_media_vdec)
target_link_libraries(rohy_player native_media_avdemuxer)
target_link_libraries(rohy_player native_media_avsource)
target_link_libraries(rohy_player native_media_codecbase)
target_link_libraries(rohy_player z)
target_link_libraries(rohy_player c)
target_link_libraries(rohy_player m)
target_link_libraries(rohy_player EGL)
target_link_libraries(rohy_player GLESv3)
target_link_libraries(rohy_player ace_ndk.z)
target_link_libraries(rohy_player uv)
target_link_libraries(rohy_player native_drm)

target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/avisynth/${OHOS_ARCH}/lib/libavisynth.so.11)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/brotli/${OHOS_ARCH}/lib/libbrotlicommon-static.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/brotli/${OHOS_ARCH}/lib/libbrotlidec-static.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/brotli/${OHOS_ARCH}/lib/libbrotlienc-static.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/bzip2_1_0_8/${OHOS_ARCH}/lib/libbz2.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/davs2/${OHOS_ARCH}/lib/libdavs2.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/fdk-aac/${OHOS_ARCH}/lib/libfdk-aac.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavcodec.so.61)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavdevice.so.61)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavfilter.so.10)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavformat.so.61)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libavutil.so.59)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libpostproc.so.58)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libswresample.so.5)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/ffmpeg/${OHOS_ARCH}/lib/libswscale.so.8)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/fontconfig/${OHOS_ARCH}/lib/libfontconfig.so.1)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/freetype2/${OHOS_ARCH}/lib/libfreetype.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/fribidi/${OHOS_ARCH}/lib/libfribidi.so.0)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/harfbuzz/${OHOS_ARCH}/lib/libharfbuzz.so.0)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/jbigkit/${OHOS_ARCH}/lib/libjbig.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/json-c/${OHOS_ARCH}/lib/libjson-c.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/kvazaar/${OHOS_ARCH}/lib/libkvazaar.so.7)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/lame/${OHOS_ARCH}/lib/libmp3lame.so.0)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/lcevc/${OHOS_ARCH}/lib/liblcevc_dec_api.so)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/lcevc/${OHOS_ARCH}/lib/liblcevc_dec_core.so)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/lcms2/${OHOS_ARCH}/lib/liblcms2.so.2)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libaom/${OHOS_ARCH}/lib/libaom.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libass/${OHOS_ARCH}/lib/libass.so.9)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libbluray/${OHOS_ARCH}/lib/libbluray.so.3)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libdav1d/${OHOS_ARCH}/lib/libdav1d.so.7)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libdeflate/${OHOS_ARCH}/lib/libdeflate.so.0)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libiconv/${OHOS_ARCH}/lib/libcharset.so.1)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libiconv/${OHOS_ARCH}/lib/libiconv.so.2)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libjpeg-turbo/${OHOS_ARCH}/lib/libjpeg.so.62)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libjpeg-turbo/${OHOS_ARCH}/lib/libturbojpeg.so.0)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libogg/${OHOS_ARCH}/lib/libogg.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libpng/${OHOS_ARCH}/lib/libpng16.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libudfread/${OHOS_ARCH}/lib/libudfread.so.3)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libunibreak/${OHOS_ARCH}/lib/libunibreak.so.6)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libvpx/${OHOS_ARCH}/lib/libvpx.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libsharpyuv.so.0)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libwebp.so.7)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libwebpdecoder.so.3)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libwebpdemux.so.2)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libwebp/${OHOS_ARCH}/lib/libwebpmux.so.3)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libxml2/${OHOS_ARCH}/lib/libxml2.so.2)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/libzip/${OHOS_ARCH}/lib/libzip.so.5)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/openh264/${OHOS_ARCH}/lib/libopenh264.so.7)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/openjpeg/${OHOS_ARCH}/lib/libopenjp2.so.7)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/openssl/${OHOS_ARCH}/lib/libcrypto.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/openssl/${OHOS_ARCH}/lib/libssl.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/opus/${OHOS_ARCH}/lib/libopus.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/rav1e/${OHOS_ARCH}/lib/librav1e.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/speex/${OHOS_ARCH}/lib/libspeex.so.1)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/tiff/${OHOS_ARCH}/lib/libtiff.so.6)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/tiff/${OHOS_ARCH}/lib/libtiffxx.so.6)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/uavs3d/${OHOS_ARCH}/lib/libuavs3d.so)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/vvenc/${OHOS_ARCH}/lib/libvvenc.so.1.13)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/x264/${OHOS_ARCH}/lib/libx264.so.164)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/lib/libx265.so)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/lib/libx265.so.215)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/lib/libx265_main10.so)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/x265/${OHOS_ARCH}/lib/libx265_main12.so)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/xavs2/${OHOS_ARCH}/lib/libxavs2.a)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/xvidcore/${OHOS_ARCH}/lib/libxvidcore.so.4)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/xz/${OHOS_ARCH}/lib/liblzma.so.5)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/zlib_1_3_1/${OHOS_ARCH}/lib/libz.so.1)
target_link_libraries(rohy_player ${THIRDPARTY_LIBRARY_DIR}/zstd_1_5_6/${OHOS_ARCH}/lib/libzstd.so.1)
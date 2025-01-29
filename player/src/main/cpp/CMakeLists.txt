# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(RohyPlayer)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

add_library(rohy_player_napi SHARED
    napi_init.cpp
)

target_link_libraries(rohy_player_napi PUBLIC libace_napi.z.so)

#因为此三方库中存在汇编编译的部分，所以需要修改CFLAGS参考如下，符号不可抢占且优先使用本地符号
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion -Wl,-Bsymbolic")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-int-conversion -Wl,-Bsymbolic")

# 库导入
# libass 及其依赖
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libass/${OHOS_ARCH}/lib/libass.so)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fribidi/${OHOS_ARCH}/lib/libfribidi.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/freetype2/${OHOS_ARCH}/lib/libfreetype.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/zlib/${OHOS_ARCH}/lib/libz.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/bzip2/${OHOS_ARCH}/lib/libbz2.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/brotli/${OHOS_ARCH}/lib/libbbrotlicommon-static.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/brotli/${OHOS_ARCH}/lib/libbbrotlidec-static.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/brotli/${OHOS_ARCH}/lib/libbbrotlienc-static.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libpng/${OHOS_ARCH}/lib/libpng.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/harfbuzz/${OHOS_ARCH}/lib/libharfbuzz.a)

# ffmpeg 及其依赖
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/lib/libavcodec.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/lib/libavdevice.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/lib/libavfilter.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/lib/libavformat.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/lib/libavutil.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/lib/libpostproc.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/lib/libswresample.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/lib/libswscale.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/lame/${OHOS_ARCH}/lib/libmp3lame.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libaom/${OHOS_ARCH}/lib/libaom.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libogg/${OHOS_ARCH}/lib/libogg.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libvorbis/${OHOS_ARCH}/lib/libvorbis.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libvorbis/${OHOS_ARCH}/lib/libvorbisenc.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libvorbis/${OHOS_ARCH}/lib/libvorbisfile.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/openssl_3_4_0/${OHOS_ARCH}/lib/libcrypto.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/openssl_3_4_0/${OHOS_ARCH}/lib/libssl.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/opus/${OHOS_ARCH}/lib/libopus.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x264/${OHOS_ARCH}/lib/libx264.a)
target_link_libraries(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x265/${OHOS_ARCH}/lib/libx265.a)

# 头文件导入
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libass/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fribidi/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/freetype2/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/zlib/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/bzip2/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/brotli/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libpng/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/harfbuzz/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/FFmpeg/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/lame/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libaom/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libogg/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libvorbis/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/openssl_3_4_0/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/opus/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x264/${OHOS_ARCH}/include)
target_include_directories(rohy_player_napi PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/x265/${OHOS_ARCH}/include)
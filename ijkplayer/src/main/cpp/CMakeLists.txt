# the minimum version of CMake.
cmake_minimum_required(VERSION 3.4.1)
project(ijkplayer)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-int-conversion -Wl,-Bsymbolic")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-int-conversion -Wl,-Bsymbolic")
set(CMAKE_SKIP_RPATH TRUE)

add_subdirectory(ijksdl)
add_subdirectory(ijkplayer)

add_definitions(-DOHOS_PLATFORM)

add_library(ijkplayer_napi SHARED
            napi/ijkplayer_napi_init.cpp
            napi/ijkplayer_napi.cpp
            napi/ijkplayer_napi_manager.cpp
            proxy/ijkplayer_napi_proxy.cpp
            utils/hashmap/data_struct.c
            utils/ffmpeg/custom_ffmpeg_log.c
            utils/napi/napi_utils.cpp
            )

add_library(ijkplayer_audio_napi SHARED
            napi/ijkplayer_napi_audio_init.cpp
            napi/ijkplayer_napi.cpp
            proxy/ijkplayer_napi_proxy.cpp
            utils/hashmap/data_struct.c
            utils/ffmpeg/custom_ffmpeg_log.c
            utils/napi/napi_utils.cpp
            )

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ijkplayer)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/ijksdl)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/proxy)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/napi)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/utils/napi)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third_party/ffmpeg)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third_party/ffmpeg/${OHOS_ARCH}/include)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third_party/openssl3/${OHOS_ARCH}/include)

target_link_libraries(ijkplayer_napi PUBLIC ijkplayer)
target_link_libraries(ijkplayer_napi PUBLIC ijksdl)
target_link_libraries(ijkplayer_napi PUBLIC EGL)
target_link_libraries(ijkplayer_napi PUBLIC GLESv3)
target_link_libraries(ijkplayer_napi PUBLIC hilog_ndk.z)
target_link_libraries(ijkplayer_napi PUBLIC ace_ndk.z)
target_link_libraries(ijkplayer_napi PUBLIC ace_napi.z)
target_link_libraries(ijkplayer_napi PUBLIC uv)

target_link_libraries(ijkplayer_audio_napi PUBLIC ijkplayer)
target_link_libraries(ijkplayer_audio_napi PUBLIC ijksdl)
target_link_libraries(ijkplayer_audio_napi PUBLIC EGL)
target_link_libraries(ijkplayer_audio_napi PUBLIC GLESv3)
target_link_libraries(ijkplayer_audio_napi PUBLIC hilog_ndk.z)
target_link_libraries(ijkplayer_audio_napi PUBLIC ace_ndk.z)
target_link_libraries(ijkplayer_audio_napi PUBLIC ace_napi.z)
target_link_libraries(ijkplayer_audio_napi PUBLIC uv)

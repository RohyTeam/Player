# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(RohyPlayer)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fontconfig/${OHOS_ARCH}/include
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libpng/${OHOS_ARCH}/include
                    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libass/${OHOS_ARCH}/include)

add_library(player SHARED
            napi_init.cpp
            subtitle/subtitle_napi.cpp
            subtitle/png_utils.cpp
            utils/napi_utils.cpp
            )

target_link_libraries(player PUBLIC libace_napi.z.so libace_ndk.z.so libhilog_ndk.z.so libGLESv3.so libEGL.so libnative_window.so)
target_link_libraries(player PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libass/${OHOS_ARCH}/lib/libass.so.9)
target_link_libraries(player PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/libpng/${OHOS_ARCH}/lib/libpng16.so.16)
target_link_libraries(player PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fontconfig/${OHOS_ARCH}/lib/libfontconfig.so)
target_link_libraries(player PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/fribidi/${OHOS_ARCH}/lib/libfribidi.so)
target_link_libraries(player PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/freetype2/${OHOS_ARCH}/lib/libfreetype.a)
target_link_libraries(player PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/harfbuzz/${OHOS_ARCH}/lib/libharfbuzz.so)
target_link_libraries(player PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/zlib/${OHOS_ARCH}/lib/libz.so.1)
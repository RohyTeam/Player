//
// Created on 2025/8/18.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_ROHY_LOGGER_H
#define ROHYPLAYER_ROHY_LOGGER_H

#include <hilog/log.h>

#define ROHY_INFO(tag, ...) ((void)OH_LOG_Print(LOG_APP, LOG_INFO, 0, (tag), __VA_ARGS__))
#define ROHY_WARNING(tag, ...) ((void)OH_LOG_Print(LOG_APP, LOG_WARNING, 0, (tag), __VA_ARGS__))
#define ROHY_ERROR(tag, ...) ((void)OH_LOG_Print(LOG_APP, LOG_ERROR, 0, (tag), __VA_ARGS__))

#endif //ROHYPLAYER_ROHY_LOGGER_H

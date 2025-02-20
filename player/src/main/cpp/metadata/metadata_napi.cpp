//
// Created on 2025/2/19.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "metadata_napi.h"

#include "hilog/log.h"
#include "utils/napi_utils.h"
#include <cstdint>
#include <libavformat/avformat.h>
#include <string>

void setPropertyValue(napi_env env, napi_value obj, const char* propertyName, int64_t value) {
    napi_value jsValue;
    napi_create_int64(env, value, &jsValue);
    napi_set_named_property(env, obj, propertyName, jsValue);
}

napi_value MetadataManager::GetMetadata(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "test", "FUCK: get metadata");
    
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    std::string fileUrl;
    NapiUtils::JsValueToString(env, args[0], 2048, fileUrl);
    
    AVFormatContext* aVFormatContext = avformat_alloc_context();
    if (avformat_open_input(&aVFormatContext, fileUrl.c_str(), NULL, NULL) != 0) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "avFormat", "Failed to open input");
        return nullptr;
    }

    if (avformat_find_stream_info(aVFormatContext, NULL) < 0) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "avFormat", "Failed to find stream info");
        return nullptr;
    }
    
    napi_value metadata_object;
    napi_create_object(env, &metadata_object);
    
    napi_value tracksArray;
    napi_create_array(env, &tracksArray);
    
    size_t realIndex = 0;
    for (unsigned int i = 0; i < aVFormatContext->nb_streams; i++) {
        AVStream* stream = aVFormatContext->streams[i];
        AVCodecParameters* codecpar = stream->codecpar;
        
        napi_value track_object;
        napi_create_object(env, &track_object);
        
        if (codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            setPropertyValue(env, track_object, "type", 0);
            setPropertyValue(env, track_object, "codec", codecpar->codec_id);
            setPropertyValue(env, track_object, "bit_rate", codecpar->bit_rate);
            setPropertyValue(env, track_object, "width", codecpar->width);
            setPropertyValue(env, track_object, "height", codecpar->height);
            i += 1;
        } else if (codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            setPropertyValue(env, track_object, "type", 1);
            setPropertyValue(env, track_object, "codec", codecpar->codec_id);
            setPropertyValue(env, track_object, "channels", codecpar->channels);
            setPropertyValue(env, track_object, "sample_rate", codecpar->sample_rate);
            setPropertyValue(env, track_object, "frame_size", codecpar->frame_size);
            i += 1;
        } else if (codecpar->codec_type == AVMEDIA_TYPE_SUBTITLE) {
            setPropertyValue(env, track_object, "type", 3);
            setPropertyValue(env, track_object, "codec", codecpar->codec_id);
            i += 1;
        }
        napi_set_element(env, tracksArray, realIndex, track_object);
    }
    
    napi_set_named_property(env, metadata_object, "tracks", tracksArray);
    
    return metadata_object;
}
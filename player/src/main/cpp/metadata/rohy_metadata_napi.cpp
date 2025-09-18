#include <cstdint>
#include <stdio.h>
#include <string.h>
#include <fstream>
#include "hilog/log.h"
#include "metadata/rohy_metadata_exporter.h"
#include "metadata/rohy_metadata_getter.h"
#include "metadata/rohy_metadata_shared.h"
#include "utils/napi_utils.h"
#include <xxhash.h>

napi_value RohyMetadata_GetMetadata(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "GetMetadata", "Starting getting metadata");
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    std::string fileUrl;
    NapiUtils::JsValueToString(env, args[0], 2048, fileUrl);
    
    napi_valuetype headersType;
    napi_typeof(env, args[1], &headersType);
    
    std::vector<Header> headers;
    
    if (headersType != napi_undefined) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "GetMetadata", "processing headers");
        
        napi_value jsHeaders = args[1];
        
        napi_value property_names;
        napi_get_property_names(env, jsHeaders, &property_names);
        
        uint32_t properties_size; 
        napi_get_array_length(env, property_names, &properties_size);
        
        for (int i = 0; i < properties_size; i++) {
            napi_value element;
            napi_get_element(env, property_names, i, &element);
            
            std::string key;
            NapiUtils::JsValueToString(env, element, 2048, key);
            
            napi_value jsValue;
            napi_get_named_property(env, jsHeaders, key.c_str(), &jsValue);
            
            std::string value;
            NapiUtils::JsValueToString(env, jsValue, 2048, value);
            
            headers.push_back(Header {
                .key = key.c_str(),
                .value = value.c_str()
            });
        }
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "GetMetadata", "headers processed");
    }

    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "GetMetadata", "Starting extracting");
    VideoMetadata meta = RohyMetadataGetter::extract_metadata_and_cover(fileUrl.c_str(), headers);
    
    if (!meta.success) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractVideoMetadata", "Failed to extract metadata");
        return nullptr;
    }
    
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "GetMetadata", "Starting creating ArkTS object");
    napi_value video_metadata;
    napi_create_object(env, &video_metadata);
    
    NapiUtils::SetPropertyNumberValue(env, video_metadata, "duration", meta.duration);
    NapiUtils::SetPropertyNumberValue(env, video_metadata, "bitrate", meta.bitrate);
    NapiUtils::SetPropertyNumberValue(env, video_metadata, "width", meta.width);
    NapiUtils::SetPropertyNumberValue(env, video_metadata, "height", meta.height);
    NapiUtils::SetPropertyDoubleValue(env, video_metadata, "averageFramerate", meta.averageFrameRate);
    NapiUtils::SetPropertyNumberValue(env, video_metadata, "hdr", meta.hdr);
    NapiUtils::SetPropertyStringValueOrUndefined(env, video_metadata, "codec", meta.codec);
    NapiUtils::SetPropertyStringValueOrUndefined(env, video_metadata, "codecLong", meta.codec_full);
    
    if (meta.cover.size() > 0) {
        napi_value array_buffer;
        void* buffer_data = nullptr;
        napi_create_arraybuffer(env, meta.cover.size(), &buffer_data, &array_buffer);
        memcpy(buffer_data, meta.cover.data(), meta.cover.size());
        
        napi_set_named_property(env, video_metadata, "cover", array_buffer);
    }
    
    napi_value chaptersArray;
    napi_create_array(env, &chaptersArray);
    
    size_t realIndex = 0;
    for (unsigned int i = 0; i < meta.chapters.size(); i++) {
        const ChapterMetadata chapter = meta.chapters[i];
        
        napi_value chapter_object;
        napi_create_object(env, &chapter_object);
        
        NapiUtils::SetPropertyStringValueOrUndefined(env, chapter_object, "title", chapter.title);
        NapiUtils::SetPropertyNumberValue(env, chapter_object, "start", chapter.start);
        NapiUtils::SetPropertyNumberValue(env, chapter_object, "end", chapter.end);
        
        napi_set_element(env, chaptersArray, realIndex, chapter_object);
        
        realIndex += 1;
    }
    
    napi_set_named_property(env, video_metadata, "chapters", chaptersArray);
    
    napi_value tracksArray;
    napi_create_array(env, &tracksArray);
    
    realIndex = 0;
    for (unsigned int i = 0; i < meta.tracks.size(); i++) {
        const TrackMetadata track = meta.tracks[i];
        
        napi_value track_object;
        napi_create_object(env, &track_object);
        
        NapiUtils::SetPropertyNumberValue(env, track_object, "type", track.track_type);
        NapiUtils::SetPropertyNumberValue(env, track_object, "index", track.index);
        NapiUtils::SetPropertyStringValueOrUndefined(env, track_object, "title", track.title);
        NapiUtils::SetPropertyStringValueOrUndefined(env, track_object, "language", track.language);
        NapiUtils::SetPropertyStringValueOrUndefined(env, track_object, "codec", track.codec);
        NapiUtils::SetPropertyStringValueOrUndefined(env, track_object, "codecLong", track.codec_full);
        
        if (track.track_type == TrackType::Video) {
            NapiUtils::SetPropertyNumberValue(env, track_object, "width", track.width);
            NapiUtils::SetPropertyNumberValue(env, track_object, "height", track.height);
            NapiUtils::SetPropertyNumberValue(env, track_object, "duration", track.duration);
            NapiUtils::SetPropertyDoubleValue(env, track_object, "averageFramerate", track.averageFrameRate);
            NapiUtils::SetPropertyNumberValue(env, track_object, "bitrate", track.bitrate);
            NapiUtils::SetPropertyNumberValue(env, track_object, "hdr", track.hdr);
        } else if (track.track_type == TrackType::Audio) {
            NapiUtils::SetPropertyNumberValue(env, track_object, "sampleRate", track.samplerate);
        } else if (track.track_type == TrackType::Attachment) {
            NapiUtils::SetPropertyStringValue(env, track_object, "filename", track.filename);
            NapiUtils::SetPropertyStringValue(env, track_object, "mimetype", track.mimetype);
        }
        
        napi_set_element(env, tracksArray, realIndex, track_object);
        
        realIndex += 1;
    }
    
    napi_set_named_property(env, video_metadata, "tracks", tracksArray);
    
    return video_metadata;
}

napi_value RohyMetadata_ExtractTracks(napi_env env, napi_callback_info info) {
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "Starting extracting tracks");
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ParseId", "GetContext napi_get_cb_info failed");
        return nullptr;
    }
    
    std::string fileUrl;
    NapiUtils::JsValueToString(env, args[0], 2048, fileUrl);
    
    napi_value extractingTracks = args[1];
    uint32_t tracks_size;
    napi_get_array_length(env, extractingTracks, &tracks_size);
    
    if (tracks_size == 0)
        return nullptr;
    
    std::vector<StreamExtractConfig> tracks;
    
    for (int i = 0; i < tracks_size; i++) {
        napi_value track;
        napi_get_element(env, extractingTracks, i, &track);
        
        napi_value jsTrackIndex;
        napi_get_named_property(env, track, "index", &jsTrackIndex);
        
        int32_t trackIndex;
        napi_get_value_int32(env, jsTrackIndex, &trackIndex);
        
        if (trackIndex < 0)
            continue;
        
        napi_value jsDest;
        napi_get_named_property(env, track, "dest", &jsDest);
        
        std::string dest;
        NapiUtils::JsValueToString(env, jsDest, 2048, dest);
        
        tracks.push_back(StreamExtractConfig {
            .stream_index = trackIndex,
            .output_file = dest.c_str() 
        });
    }
    
    if (tracks.size() == 0) // because track index smaller than 0 will be ignored
        return nullptr;
    
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "There are tracks need to be extracted");
    
    napi_valuetype headersType;
    napi_typeof(env, args[2], &headersType);
    
    std::vector<Header> headers;
    
    if (headersType != napi_undefined) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "processing headers");
        
        napi_value jsHeaders = args[2];
        
        napi_value property_names;
        napi_get_property_names(env, jsHeaders, &property_names);
        
        uint32_t properties_size; 
        napi_get_array_length(env, property_names, &properties_size);
        
        for (int i = 0; i < properties_size; i++) {
            napi_value element;
            napi_get_element(env, property_names, i, &element);
            
            std::string key;
            NapiUtils::JsValueToString(env, element, 2048, key);
            
            napi_value jsValue;
            napi_get_named_property(env, jsHeaders, key.c_str(), &jsValue);
            
            std::string value;
            NapiUtils::JsValueToString(env, jsValue, 2048, value);
            
            headers.push_back(Header {
                .key = key.c_str(),
                .value = value.c_str()
            });
        }
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "GetMetadata", "headers processed");
    }
    
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "Ready to extract tracks");
    RohyMetadataExporter::extract_multiple_streams(fileUrl, headers, tracks);
    
    return nullptr;
}

napi_value RohyMetadata_HashFile(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    if (napi_ok != napi_get_cb_info(env, info, &argc, args, nullptr, nullptr)) {
        return nullptr;
    }
    
    std::string file_path;
    NapiUtils::JsValueToString(env, args[0], 2048, file_path);
    
    napi_value jsSize = args[1];
    int64_t file_size;
    napi_get_value_int64(env, jsSize, &file_size);
    
    const size_t SAMPLE_POINTS = 4;
    const size_t SAMPLE_SIZE = 4096;
    
    std::ifstream file(file_path, std::ios::binary);
    if (!file.is_open()) {
        return nullptr;
    }
    
    XXH3_state_t* state = XXH3_createState();
    XXH3_128bits_reset(state);
    
    for (size_t i = 0; i < SAMPLE_POINTS; ++i) {
        size_t offset = (file_size * i) / SAMPLE_POINTS;
        
        file.seekg(offset);
        if (!file) {
            XXH3_freeState(state);
            return nullptr;
        }
        
        char buffer[SAMPLE_SIZE];
        size_t to_read = std::min(SAMPLE_SIZE, file_size - offset);
        file.read(buffer, to_read);
        
        if (file.gcount() != to_read) {
            XXH3_freeState(state);
            return nullptr;
        }
        
        XXH3_128bits_update(state, buffer, to_read);
    }
    
    XXH128_hash_t hash = XXH3_128bits_digest(state);
    XXH3_freeState(state);
    
    char hash_str[33];
    snprintf(hash_str, sizeof(hash_str), 
             "%016llx%016llx", hash.high64, hash.low64);
    
    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "Fuck!", "FUCK: file hash is %{public}s", hash_str);
    
    return NapiUtils::CStringToJsString(env, hash_str);
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "RohyMetedata_getMetadata", nullptr, RohyMetadata_GetMetadata, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "RohyMetadata_extractTracks", nullptr, RohyMetadata_ExtractTracks, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "RohyMetadata_hashFile", nullptr, RohyMetadata_HashFile, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module rohyMetadataModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "rohy_metadata",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterPlayerModule(void)
{
    napi_module_register(&rohyMetadataModule);
}

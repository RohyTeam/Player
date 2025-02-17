/*
 * Copyright (C) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "ijkplayer_napi_proxy.h"
static std::unordered_map<std::string, IjkMediaPlayer *> GLOBAL_IJKMP;
void (*post_event)(int what, int arg1, int arg2, char *obj, std::string id);

void IJKPlayerNapiProxy::message_loop_callback(void (*pe)(int what, int arg1, int arg2, char *obj,
                                               std::string id))
{
    post_event = pe;
}

static void message_loop_n(IjkMediaPlayer *mp) {
    LOGI("napi_proxy-->message_loop_n");
    void *weak_thiz = ijkmp_get_weak_thiz(mp);

    while (1) {
        AVMessage msg;
        LOGI("napi_proxy-->message_loop_n-->go");
        int retval = ijkmp_get_msg(mp, &msg, 1);
        LOGI("napi_proxy-->message_loop_n-->go retval = %d", retval);
        if (retval <= 0) {
            break;
        }
        char *id = ijkmp_get_id(mp);
        if (!id) {
            break;
        }
        std::string idStr(id);

        switch (msg.what) {
            LOGI("napi_proxy-->message_loop_n-->go-->msg:%d", msg.what);
            case FFP_MSG_FLUSH:
                MPTRACE("FFP_MSG_FLUSH:\n");
                post_event(MEDIA_NOP, 0, 0, nullptr, idStr);
                break;
            case FFP_MSG_ERROR:
                MPTRACE("FFP_MSG_ERROR: %d\n", msg.arg1);
                post_event(MEDIA_ERROR, MEDIA_ERROR_IJK_PLAYER, msg.arg1, nullptr, idStr);
                break;
            case FFP_MSG_PREPARED:
                MPTRACE("FFP_MSG_PREPARED:\n");
                post_event(MEDIA_PREPARED, 0, 0, nullptr, idStr);
                break;
            case FFP_MSG_COMPLETED:
                MPTRACE("FFP_MSG_COMPLETED:\n");
                post_event(MEDIA_PLAYBACK_COMPLETE, 0, 0, nullptr, idStr);
                break;
            case FFP_MSG_VIDEO_SIZE_CHANGED:
                MPTRACE("FFP_MSG_VIDEO_SIZE_CHANGED: %d, %d\n", msg.arg1, msg.arg2);
                post_event(MEDIA_SET_VIDEO_SIZE, msg.arg1, msg.arg2, nullptr, idStr);
                break;
            case FFP_MSG_SAR_CHANGED:
                MPTRACE("FFP_MSG_SAR_CHANGED: %d, %d\n", msg.arg1, msg.arg2);
                post_event(MEDIA_SET_VIDEO_SAR, msg.arg1, msg.arg2, nullptr, idStr);
                break;
            case FFP_MSG_VIDEO_RENDERING_START:
                MPTRACE("FFP_MSG_VIDEO_RENDERING_START:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_VIDEO_RENDERING_START, 0, nullptr, idStr);
                break;
            case FFP_MSG_AUDIO_RENDERING_START:
                MPTRACE("FFP_MSG_AUDIO_RENDERING_START:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_AUDIO_RENDERING_START, 0, nullptr, idStr);
                break;
            case FFP_MSG_VIDEO_ROTATION_CHANGED:
                MPTRACE("FFP_MSG_VIDEO_ROTATION_CHANGED: %d\n", msg.arg1);
                post_event(MEDIA_INFO, MEDIA_INFO_VIDEO_ROTATION_CHANGED, msg.arg1, nullptr, idStr);
                break;
            case FFP_MSG_AUDIO_DECODED_START:
                MPTRACE("FFP_MSG_AUDIO_DECODED_START:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_AUDIO_DECODED_START, 0, nullptr, idStr);
                break;
            case FFP_MSG_VIDEO_DECODED_START:
                MPTRACE("FFP_MSG_VIDEO_DECODED_START:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_VIDEO_DECODED_START, 0, nullptr, idStr);
                break;
            case FFP_MSG_OPEN_INPUT:
                MPTRACE("FFP_MSG_OPEN_INPUT:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_OPEN_INPUT, 0, nullptr, idStr);
                break;
            case FFP_MSG_FIND_STREAM_INFO:
                MPTRACE("FFP_MSG_FIND_STREAM_INFO:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_FIND_STREAM_INFO, 0, nullptr, idStr);
                break;
            case FFP_MSG_COMPONENT_OPEN:
                MPTRACE("FFP_MSG_COMPONENT_OPEN:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_COMPONENT_OPEN, 0, nullptr, idStr);
                break;
            case FFP_MSG_BUFFERING_START:
                MPTRACE("FFP_MSG_BUFFERING_START:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_BUFFERING_START, msg.arg1, nullptr, idStr);
                break;
            case FFP_MSG_BUFFERING_END:
                MPTRACE("FFP_MSG_BUFFERING_END:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_BUFFERING_END, msg.arg1, nullptr, idStr);
                break;
            case FFP_MSG_BUFFERING_UPDATE:
                post_event(MEDIA_BUFFERING_UPDATE, msg.arg1, msg.arg2, nullptr, idStr);
                break;
            case FFP_MSG_BUFFERING_BYTES_UPDATE:
                break;
            case FFP_MSG_BUFFERING_TIME_UPDATE:
                break;
            case FFP_MSG_SEEK_COMPLETE:
                MPTRACE("FFP_MSG_SEEK_COMPLETE:\n");
                post_event(MEDIA_SEEK_COMPLETE, 0, 0, nullptr, idStr);
                break;
            case FFP_MSG_ACCURATE_SEEK_COMPLETE:
                MPTRACE("FFP_MSG_ACCURATE_SEEK_COMPLETE:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_MEDIA_ACCURATE_SEEK_COMPLETE, msg.arg1, nullptr, idStr);
                break;
            case FFP_MSG_PLAYBACK_STATE_CHANGED:
                break;
            case FFP_MSG_TIMED_TEXT:
                if (msg.obj) {
                    post_event(MEDIA_TIMED_TEXT, 0, 0, (char *)msg.obj, idStr);
                } else {
                    post_event(MEDIA_TIMED_TEXT, 0, 0, nullptr, idStr);
                }
                break;
            case FFP_MSG_GET_IMG_STATE:
                if (msg.obj) {
                    post_event(MEDIA_GET_IMG_STATE, msg.arg1, msg.arg2, (char *)msg.obj, idStr);
                } else {
                    post_event(MEDIA_GET_IMG_STATE, msg.arg1, msg.arg2, nullptr, idStr);
                }
                break;
            case FFP_MSG_VIDEO_SEEK_RENDERING_START:
                MPTRACE("FFP_MSG_VIDEO_SEEK_RENDERING_START:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_VIDEO_SEEK_RENDERING_START, msg.arg1, nullptr, idStr);
                break;
            case FFP_MSG_AUDIO_SEEK_RENDERING_START:
                MPTRACE("FFP_MSG_AUDIO_SEEK_RENDERING_START:\n");
                post_event(MEDIA_INFO, MEDIA_INFO_AUDIO_SEEK_RENDERING_START, msg.arg1, nullptr, idStr);
                break;
            case FFP_MSG_AUDIO_INTERRUPT:
                MPTRACE("FFP_MSG_AUDIO_INTERRUPT:\n");
                post_event(MEDIA_AUDIO_INTERRUPT, msg.arg1, msg.arg2, nullptr, idStr);
                break;
            case FFP_MSG_AUDIO_DEVICE_CHANGE:
                MPTRACE("FFP_MSG_AUDIO_DEVICE_CHANGE:\n");
                post_event(MEDIA_AUDIO_DEVICE_CHANGE, msg.arg1, msg.arg2, nullptr, idStr);
                break;
            default:
                ALOGE("unknown FFP_MSG_xxx(%d)\n", msg.what);
                break;
        }
        msg_free_res(&msg);
    }
}

static int message_loop(void *arg);

static int message_loop(void *arg) {
    LOGI("napi_proxy-->message_loop");
    IjkMediaPlayer *mp = (IjkMediaPlayer *)arg;
    message_loop_n(mp);
    ijkmp_dec_ref_p(&mp);
    return 0;
}

IjkMediaPlayer *IJKPlayerNapiProxy::get_media_player(std::string id)
{
    IjkMediaPlayer *mp = nullptr;
    std::unordered_map<std::string, IjkMediaPlayer *>::iterator it = GLOBAL_IJKMP.find(id);
    if (it != GLOBAL_IJKMP.end()) {
        mp = it->second;
    }

    if (mp) {
        ijkmp_inc_ref(mp);
    }
    return mp;
}

IjkMediaPlayer *IJKPlayerNapiProxy::set_media_player(std::string id, IjkMediaPlayer *mp)
{
    LOGI("napi_proxy-->set_media_player");
    if (mp) {
        ijkmp_inc_ref(mp);
    } else {
        std::unordered_map<std::string, IjkMediaPlayer *>::iterator it = GLOBAL_IJKMP.find(id);
        if (it != GLOBAL_IJKMP.end()) {
            mp = it->second;
        }
        ijkmp_dec_ref_p(&mp);
    }
    GLOBAL_IJKMP.insert(std::make_pair(id, mp));
    return GLOBAL_IJKMP[id];
}

void IJKPlayerNapiProxy::delete_media_player(std::string id)
{
    auto it = GLOBAL_IJKMP.find(id);
    if (it != GLOBAL_IJKMP.end()) {
        GLOBAL_IJKMP.erase(it);
    }
};

void IJKPlayerNapiProxy::IjkMediaPlayer_native_setup(void *weak_this, void *native_window) {
    LOGI("napi_proxy-->IjkMediaPlayer_native_setup");
    if (!IJKMP_GLOABL_INIT) {
        ijkmp_global_init();
    }

    IJKMP_GLOABL_INIT = true;
    GLOBAL_NATIVE_WINDOW = native_window;
    IjkMediaPlayer *mp = ijkmp_android_create(message_loop);
    IJKPlayerNapiProxy::set_media_player(id_, mp);
    ijkmp_android_set_surface(mp, native_window);
    ijkmp_set_weak_thiz(mp, weak_this);
    ijkmp_set_id(mp, (char *)id_.c_str());
    ijkmp_set_inject_opaque(mp, ijkmp_get_weak_thiz(mp));
    ijkmp_set_ijkio_inject_opaque(mp, ijkmp_get_weak_thiz(mp));
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_native_setup_audio() {
    LOGI("napi_proxy-->IjkMediaPlayer_native_setup");
    if (!IJKMP_GLOABL_INIT) {
        ijkmp_global_init();
    }

    IJKMP_GLOABL_INIT = true;
    IjkMediaPlayer *mp = ijkmp_android_create(message_loop);
    IJKPlayerNapiProxy::set_media_player(id_, mp);
    ijkmp_set_id(mp, (char *)id_.c_str());
    ijkmp_set_inject_opaque(mp, ijkmp_get_weak_thiz(mp));
    ijkmp_set_ijkio_inject_opaque(mp, ijkmp_get_weak_thiz(mp));
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_setDataSource(char *url) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_setDataSource mp NULL");
        return;
    }
    ijkmp_set_data_source(mp, url);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_setOption(int category, char *name, char *value) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_setOption mp NULL");
        return;
    }
    ijkmp_set_option(mp, category, name, value);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_setOptionLong(int category, char *name, int64_t value) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_setOptionLong mp NULL");
        return;
    }
    ijkmp_set_option_int(mp, category, name, value);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_prepareAsync() {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_prepareAsync mp NULL");
        return;
    }
    ijkmp_prepare_async(mp);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_start() {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_start mp NULL");
        return;
    }
    ijkmp_start(mp);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_pause() {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_pause mp NULL");
        return;
    }
    ijkmp_pause(mp);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_seekTo(int64_t msec) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_seekTo mp NULL");
        return;
    }
    ijkmp_seek_to(mp, msec);
    ijkmp_dec_ref_p(&mp);
}

bool IJKPlayerNapiProxy::IjkMediaPlayer_isPlaying() {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_isPlaying mp NULL");
        return false;
    }
    bool bol = ijkmp_is_playing(mp) ? true : false;
    ijkmp_dec_ref_p(&mp);
    return bol;
}

int IJKPlayerNapiProxy::IjkMediaPlayer_getCurrentPosition() {
    int retval = 0;
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_getCurrentPosition mp NULL");
        return retval;
    }
    retval = ijkmp_get_current_position(mp);
    ijkmp_dec_ref_p(&mp);
    return retval;
}

int IJKPlayerNapiProxy::IjkMediaPlayer_getDuration() {
    int retval = 0;
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_getDuration mp NULL");
        return retval;
    }
    retval = ijkmp_get_duration(mp);
    ijkmp_dec_ref_p(&mp);
    return retval;
}

void IJKPlayerNapiProxy::IjkMediaPlayer_stop() {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_stop mp NULL");
        return;
    }
    ijkmp_stop(mp);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_release() {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_release mp NULL");
        return;
    }
    ijkmp_shutdown(mp);
    IJKPlayerNapiProxy::set_media_player(id_, NULL);
    delete_media_player(id_);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_reset() {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_reset mp NULL");
        return;
    }
    ijkmp_android_set_surface(mp, NULL);
    void *weak_thiz = ijkmp_set_weak_thiz(mp, NULL);
    IjkMediaPlayer_release();
    LOGI("napi_proxy-->IjkMediaPlayer_reset");
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::IjkMediaPlayer_setVolume(float leftVolume, float rightVolume) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_setVolume mp NULL");
        return;
    }
    ijkmp_android_set_volume(mp, leftVolume, rightVolume);
    ijkmp_dec_ref_p(&mp);
}

void IJKPlayerNapiProxy::ijkMediaPlayer_setPropertyFloat(int id, float value) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->ijkMediaPlayer_setPropertyFloat mp NULL");
        return;
    }
    ijkmp_set_property_float(mp, id, value);
    ijkmp_dec_ref_p(&mp);
}

float IJKPlayerNapiProxy::ijkMediaPlayer_getPropertyFloat(int id, float default_value) {
    float retval = 0;
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->ijkMediaPlayer_getPropertyFloat mp NULL");
        return retval;
    }
    retval = ijkmp_get_property_float(mp, id, default_value);
    if (retval == -1) {
        LOGE("napi_proxy-->ijkMediaPlayer_getPropertyFloat fail");
        retval = 0;
    }
    ijkmp_dec_ref_p(&mp);
    return retval;
}

void IJKPlayerNapiProxy::ijkMediaPlayer_setPropertyLong(int id, long value) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->ijkMediaPlayer_setPropertyLong mp NULL");
        return;
    }
    ijkmp_set_property_int64(mp, id, value);
    ijkmp_dec_ref_p(&mp);
}

long IJKPlayerNapiProxy::ijkMediaPlayer_getPropertyLong(int id, long default_value) {
    long retval = 0;
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->ijkMediaPlayer_getPropertyLong mp NULL");
        return retval;
    }
    retval = ijkmp_get_property_int64(mp, id, default_value);
    if (retval == -1) {
        LOGE("napi_proxy-->ijkMediaPlayer_getPropertyLong fail");
        retval = 0;
    }
    ijkmp_dec_ref_p(&mp);
    return retval;
}

int IJKPlayerNapiProxy::IjkMediaPlayer_getAudioSessionId() {
    int audio_session_id = 0;
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_getAudioSessionId mp NULL");
        return audio_session_id;
    }
    audio_session_id = ijkmp_android_get_audio_session_id(mp);
    ijkmp_dec_ref_p(&mp);
    return audio_session_id;
}

void IJKPlayerNapiProxy::IjkMediaPlayer_setLoopCount(int loop_count) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_setLoopCount mp NULL");
        return;
    }
    ijkmp_set_loop(mp, loop_count);
    ijkmp_dec_ref_p(&mp);
}

int IJKPlayerNapiProxy::IjkMediaPlayer_getLoopCount() {
    int loopCount = 0;
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_getLoopCount mp NULL");
        return loopCount;
    }
    loopCount = ijkmp_get_loop(mp);
    ijkmp_dec_ref_p(&mp);
    return loopCount;
}

char *IJKPlayerNapiProxy::IjkMediaPlayer_getVideoCodecInfo() {
    char *codec_info = NULL;
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_getVideoCodecInfo mp NULL");
        return codec_info;
    }
    ijkmp_get_video_codec_info(mp, &codec_info);
    ijkmp_dec_ref_p(&mp);
    return codec_info;
}

char *IJKPlayerNapiProxy::IjkMediaPlayer_getAudioCodecInfo() {
    MPTRACE("%s\n", __func__);
    char *codec_info = NULL;
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_getAudioCodecInfo mp NULL");
        return codec_info;
    }
    ijkmp_get_audio_codec_info(mp, &codec_info);
    ijkmp_dec_ref_p(&mp);
    return codec_info;
}

void IJKPlayerNapiProxy::ijkMediaPlayer_setStreamSelected(int stream, bool selected) {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    if (!mp) {
        LOGE("napi_proxy-->ijkMediaPlayer_setStreamSelected mp NULL");
        return;
    }
    int ret = 0;
    ret = ijkmp_set_stream_selected(mp, stream, selected);
    if (ret < 0) {
        LOGI("failed to %s %d", selected ? "select" : "deselect", stream);
    }
    ijkmp_dec_ref_p(&mp);
}

const char *getFromMediaMetaByKey(IjkMediaMeta *meta, char *key) {
    const char *value = ijkmeta_get_string_l(meta, key);
    return value;
}

static void IjkMediaPlayerFillHashMap(const char *type, HashMap map, IjkMediaMeta *streamRawMeta)
{
    map->put(map, IJKM_KEY_CODEC_NAME,
             getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_CODEC_NAME));
    map->put(map, IJKM_KEY_CODEC_PROFILE,
             getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_CODEC_PROFILE));
    map->put(map, IJKM_KEY_CODEC_LEVEL,
             getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_CODEC_LEVEL));
    map->put(map, IJKM_KEY_CODEC_LONG_NAME,
             getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_CODEC_LONG_NAME));
    map->put(map, IJKM_KEY_CODEC_PIXEL_FORMAT,
             getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_CODEC_PIXEL_FORMAT));
    map->put(map, IJKM_KEY_BITRATE, getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_BITRATE));
    map->put(map, IJKM_KEY_CODEC_PROFILE_ID,
             getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_CODEC_PROFILE_ID));
    if (strcmp(type, IJKM_VAL_TYPE__VIDEO) == 0) {
        map->put(map, IJKM_KEY_WIDTH, getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_WIDTH));
        map->put(map, IJKM_KEY_HEIGHT,
                 getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_HEIGHT));
        map->put(map, IJKM_KEY_FPS_NUM,
                 getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_FPS_NUM));
        map->put(map, IJKM_KEY_TBR_NUM,
                 getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_TBR_NUM));
        map->put(map, IJKM_KEY_TBR_DEN,
                 getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_TBR_DEN));
        map->put(map, IJKM_KEY_SAR_NUM,
                 getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_SAR_NUM));
        map->put(map, IJKM_KEY_SAR_DEN,
                 getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_SAR_DEN));
    } else if (strcmp(type, IJKM_VAL_TYPE__AUDIO) == 0) {
        map->put(map, IJKM_KEY_SAMPLE_RATE,
                 getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_SAMPLE_RATE));
        map->put(map, IJKM_KEY_CHANNEL_LAYOUT,
                 getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_CHANNEL_LAYOUT));
    }
}

HashMap IJKPlayerNapiProxy::IjkMediaPlayer_getMediaMeta() {
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    HashMap map = hashmap_create();
    if (!mp) {
        LOGE("napi_proxy-->IjkMediaPlayer_getMediaMeta mp NULL");
        return map;
    }
    IjkMediaMeta *meta = ijkmp_get_meta_l(mp);
    if (!meta) {
        LOGE("napi_proxy-->IjkMediaPlayer_getMediaMeta meta NULL");
        ijkmp_dec_ref_p(&mp);
        return map;
    }
    size_t count = ijkmeta_get_children_count_l(meta);
    for (size_t i = 0; i < count; ++i) {
        IjkMediaMeta *streamRawMeta = ijkmeta_get_child_l(meta, i);
        if (streamRawMeta) {
            map->put(map, IJKM_KEY_TYPE, getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_TYPE));
            map->put(map, IJKM_KEY_TYPE, getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_TYPE));
            map->put(map, IJKM_KEY_LANGUAGE, getFromMediaMetaByKey(streamRawMeta, IJKM_KEY_LANGUAGE));
            const char *type = ijkmeta_get_string_l(streamRawMeta, IJKM_KEY_TYPE);
            if (type != nullptr) {
                IjkMediaPlayerFillHashMap(type, map, streamRawMeta);
            }
        }
    }
    ijkmp_dec_ref_p(&mp);
    return map;
}

void IJKPlayerNapiProxy::IjkMediaPlayer_native_openlog() {
    OHOS_LOG_ON = true;
    open_custom_ffmpeg_log_print();
}

int IJKPlayerNapiProxy::IjkMediaPlayer_startRecord(const char *recordFilePath)
{
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    int retval = 0;
    if (mp) {
        retval = ijkmp_start_record(mp, recordFilePath);
    }
    ijkmp_dec_ref_p(&mp);
    return retval;
}
int IJKPlayerNapiProxy::IjkMediaPlayer_stopRecord()
{
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    int retval = 0;
    if (mp) {
        retval = ijkmp_stop_record(mp);
    }
    ijkmp_dec_ref_p(&mp);
    return retval;
}

int IJKPlayerNapiProxy::IjkMediaPlayer_isRecord()
{
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    int retval = 0;
    if (mp) {
        retval = ijkmp_is_record(mp);
    }
    ijkmp_dec_ref_p(&mp);
    return retval;
}

int IJKPlayerNapiProxy::IjkMediaPlayer_getCurrentFrame(const char *saveFilePath)
{
    IjkMediaPlayer *mp = IJKPlayerNapiProxy::get_media_player(id_);
    int retval = 0;
    if (mp) {
        retval = ijkmp_get_current_frame(mp, saveFilePath);
    }
    ijkmp_dec_ref_p(&mp);
    return retval;
}


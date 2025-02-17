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

#ifndef ijkplayer_ijkplayer_napi_proxy.h_H
#define ijkplayer_ijkplayer_napi_proxy.h_H
#include <string>
#include <stdio.h>
#include <pthread.h>
#include <unistd.h>
#ifdef __cplusplus
extern "C" {
#endif
#include "../utils/hashmap/data_struct.h"
#include "../ijkplayer/ijkplayer_android.h"
#include "../utils/ffmpeg/custom_ffmpeg_log.h"
#ifdef __cplusplus
}
#endif

class IJKPlayerNapiProxy {

  public:
    IJKPlayerNapiProxy(std::string &id) : id_(id){};
    void message_loop_callback(void (*pe)(int what, int arg1, int arg2, char *obj, std::string id));
    void IjkMediaPlayer_native_setup(void *weak_this, void *native_window);
    void IjkMediaPlayer_native_setup_audio();
    void IjkMediaPlayer_setDataSource(char *url);
    void IjkMediaPlayer_setOption(int category, char *name, char *value);
    void IjkMediaPlayer_setOptionLong(int category, char *name, int64_t value);
    void IjkMediaPlayer_prepareAsync();
    void IjkMediaPlayer_start();
    void IjkMediaPlayer_stop();
    void IjkMediaPlayer_pause();
    void IjkMediaPlayer_seekTo(int64_t msec);
    bool IjkMediaPlayer_isPlaying();
    int IjkMediaPlayer_getCurrentPosition();
    int IjkMediaPlayer_getDuration();
    void IjkMediaPlayer_release();
    void IjkMediaPlayer_reset();
    void IjkMediaPlayer_setVolume(float leftVolume, float rightVolume);
    void IjkMediaPlayer_native_setLogLevel(int32_t level);
    void ijkMediaPlayer_setPropertyFloat(int id, float value);
    float ijkMediaPlayer_getPropertyFloat(int id, float default_value);
    void ijkMediaPlayer_setPropertyLong(int id, long value);
    long ijkMediaPlayer_getPropertyLong(int id, long default_value);
    int IjkMediaPlayer_getAudioSessionId();
    void IjkMediaPlayer_setLoopCount(int loop_count);
    int IjkMediaPlayer_getLoopCount();
    char *IjkMediaPlayer_getVideoCodecInfo();
    char *IjkMediaPlayer_getAudioCodecInfo();
    void ijkMediaPlayer_setStreamSelected(int stream, bool selected);
    HashMap IjkMediaPlayer_getMediaMeta();
    void IjkMediaPlayer_native_openlog();
    IjkMediaPlayer *set_media_player(std::string id, IjkMediaPlayer *mp);
    IjkMediaPlayer *get_media_player(std::string id);
    void delete_media_player(std::string id);
    
    int IjkMediaPlayer_startRecord(const char *recordFilePath);
    int IjkMediaPlayer_stopRecord();
    int IjkMediaPlayer_isRecord();
    int IjkMediaPlayer_getCurrentFrame(const char *saveFilePath);
  public:
    std::string id_;
    void *GLOBAL_NATIVE_WINDOW = nullptr;
    bool IJKMP_GLOABL_INIT = false;
    typedef struct player_fields_t {
        pthread_mutex_t mutex;
    } player_fields_t;
    player_fields_t g_clazz;
};
#endif //ijkplayer_ijkplayer_napi_proxy.h_H

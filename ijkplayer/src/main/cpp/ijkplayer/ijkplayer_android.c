/*
 * ijkplayer_android.c
 *
 * Copyright (c) 2013 Bilibili
 * Copyright (c) 2013 Zhang Rui <bbcallen@gmail.com>
 *
 * This file is part of ijkPlayer.
 *
 * ijkPlayer is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * ijkPlayer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with ijkPlayer; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "ijkplayer_android.h"

#include "ff_fferror.h"
#include "ff_ffplay.h"
#include "ijkplayer_internal.h"
#include "pipeline/ffpipeline_android.h"
#include "../ijksdl/video/ijksdl_vout_android_surface.h"

IjkMediaPlayer *ijkmp_android_create(int(*msg_loop)(void*))
{
    IjkMediaPlayer *mp = ijkmp_create(msg_loop);
    if (!mp)
        goto fail;

    mp->ffplayer->vout = SDL_VoutAndroid_CreateForAndroidSurface();
    if (!mp->ffplayer->vout)
        goto fail;

    mp->ffplayer->pipeline = ffpipeline_create_from_android(mp->ffplayer);
    if (!mp->ffplayer->pipeline)
        goto fail;

    ffpipeline_set_vout(mp->ffplayer->pipeline, mp->ffplayer->vout);

    return mp;

fail:
    ijkmp_dec_ref_p(&mp);
    return NULL;
}


void ijkmp_android_set_surface_l(IjkMediaPlayer *mp, void *native_window)
{
    if (!mp || !mp->ffplayer || !mp->ffplayer->vout)
        return;

    SDL_VoutAndroid_SetAndroidSurface( mp->ffplayer->vout, native_window);
    ffpipeline_set_surface(mp->ffplayer->pipeline, native_window);
}

void ijkmp_android_set_surface(IjkMediaPlayer *mp,void *native_window)
{
    if (!mp) return;
    pthread_mutex_lock(&mp->mutex);
    ijkmp_android_set_surface_l(mp, native_window);
    pthread_mutex_unlock(&mp->mutex);
}


void ijkmp_android_set_volume(IjkMediaPlayer *mp, float left, float right)
{
    if (!mp) return;
    pthread_mutex_lock(&mp->mutex);
    if (mp && mp->ffplayer && mp->ffplayer->pipeline) {
        ffpipeline_set_volume(mp->ffplayer->pipeline, &left,&right);
    }
    pthread_mutex_unlock(&mp->mutex);
}

int ijkmp_android_get_audio_session_id(IjkMediaPlayer *mp)
{
    int audio_session_id = 0;
    if (!mp) return audio_session_id;

    pthread_mutex_lock(&mp->mutex);
    if (mp && mp->ffplayer && mp->ffplayer->aout) {
        audio_session_id = SDL_AoutGetAudioSessionId(mp->ffplayer->aout);
    }
    pthread_mutex_unlock(&mp->mutex);

    return audio_session_id;
}

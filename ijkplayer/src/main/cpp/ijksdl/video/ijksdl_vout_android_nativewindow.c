/*****************************************************************************
 * ijksdl_vout_android_nativewindow.c
 *****************************************************************************
 *
 * Copyright (c) 2013 Bilibili
 * copyright (c) 2013 Zhang Rui <bbcallen@gmail.com>
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

#include "ijksdl_vout_android_nativewindow.h"

#include <stdio.h>

#include "ijksdl_vout.h"
#include "ijksdl_vout_internal.h"
#include "ijksdl_container.h"
#include "ijksdl_egl.h"
#include "ffmpeg/ijksdl_vout_overlay_ffmpeg.h"
#include "../ijksdl_inc_internal_android.h"
#include <syslog.h>

#ifndef AMCTRACE
#define AMCTRACE(...)
#endif


typedef struct SDL_Vout_Opaque {
    EGLNativeWindowType   * native_window;
//    SDL_AMediaCodec * acodec;
    int              null_native_window_warned; // reduce log for null window
    int              next_buffer_id;

    ISDL_Array       overlay_manager;
    ISDL_Array       overlay_pool;

    IJK_EGL         * egl;
} SDL_Vout_Opaque;

static SDL_VoutOverlay * func_create_overlay_l(int width, int height, int frame_format, SDL_Vout * vout)
{
    switch (frame_format) {
        case IJK_AV_PIX_FMT__ANDROID_MEDIACODEC:
//        return SDL_VoutAMediaCodec_CreateOverlay(width, height, vout);
        default:
        return SDL_VoutFFmpeg_CreateOverlay(width, height, frame_format, vout);
    }
}

static SDL_VoutOverlay * func_create_overlay(int width, int height, int frame_format, SDL_Vout * vout)
{
    SDL_LockMutex(vout->mutex);
    SDL_VoutOverlay * overlay = func_create_overlay_l(width, height, frame_format, vout);
    SDL_UnlockMutex(vout->mutex);
    return overlay;
}

static void func_free_l(SDL_Vout * vout)
{
    if (!vout)
        return;

    SDL_Vout_Opaque * opaque = vout->opaque;
    if (opaque) {
//        SDL_AMediaCodecBufferProxy ** begin = (SDL_AMediaCodecBufferProxy **)ISDL_Array__begin(&opaque->overlay_manager);
//        SDL_AMediaCodecBufferProxy ** end = (SDL_AMediaCodecBufferProxy **)ISDL_Array__end(&opaque->overlay_manager);
//        for (; begin < end; ++begin) {
//            SDL_AMediaCodecBufferProxy_destroyP(begin);
//        }
        ISDL_Array__clear(&opaque->overlay_pool);
        ISDL_Array__clear(&opaque->overlay_manager);

        if (opaque->native_window) {
            //ANativeWindow_release(opaque->native_window);
//            NativeLayerHandle(opaque->native_window, RELEASE_REF);
            opaque->native_window = NULL;
        }

        IJK_EGL_freep(&opaque->egl);

//        SDL_AMediaCodec_decreaseReferenceP(&opaque->acodec);
    }

    SDL_Vout_FreeInternal(vout);
}

static int func_display_overlay_l(SDL_Vout * vout, SDL_VoutOverlay * overlay)
{
    LOGI("func_display_overlay_l");
    SDL_Vout_Opaque * opaque = vout->opaque;
    EGLNativeWindowType * native_window = opaque->native_window;

    if (!native_window) {
        if (!opaque->null_native_window_warned) {
            opaque->null_native_window_warned = 1;
            ALOGW("func_display_overlay_l: NULL native_window");
        }
        return -1;
    } else {
        opaque->null_native_window_warned = 1;
    }

    if (!overlay) {
        ALOGE("func_display_overlay_l: NULL overlay");
        return -1;
    }

    if (overlay->w <= 0 || overlay->h <= 0) {
        ALOGE("func_display_overlay_l: invalid overlay dimensions(%d, %d)", overlay->w, overlay->h);
        return -1;
    }
    switch (overlay->format) {
        case SDL_FCC__AMC: {
            // only ANativeWindow support
            IJK_EGL_terminate(opaque->egl);
//            return SDL_VoutOverlayAMediaCodec_releaseFrame_l(overlay, NULL, true);
        }
        case SDL_FCC_RV24:
        case SDL_FCC_I420:
        case SDL_FCC_I444P10LE: {
            // only GLES support
            if (opaque->egl)
                return IJK_EGL_display(opaque->egl, native_window, overlay);
            break;
        }
        case SDL_FCC_YV12:
        case SDL_FCC_RV16:
        case SDL_FCC_RV32: {
            // both GLES & ANativeWindow support
           //if (vout->overlay_format == SDL_FCC__GLES2 && opaque->egl) {
                return IJK_EGL_display(opaque->egl, native_window, overlay);
         //  }
           break;
        }
    }

    // fallback to ANativeWindow
    IJK_EGL_terminate(opaque->egl);
    return NULL;
}

static int func_display_overlay(SDL_Vout * vout, SDL_VoutOverlay * overlay)
{
    SDL_LockMutex(vout->mutex);
    int retval = func_display_overlay_l(vout, overlay);
    SDL_UnlockMutex(vout->mutex);
    return retval;
}

static SDL_Class g_nativewindow_class = {
    .name = "ANativeWindow_Vout",
};

SDL_Vout * SDL_VoutAndroid_CreateForANativeWindow()
{
    SDL_Vout * vout = SDL_Vout_CreateInternal(sizeof(SDL_Vout_Opaque));
    if (!vout)
        return NULL;

    SDL_Vout_Opaque * opaque = vout->opaque;
    opaque->native_window = NULL;
    if (ISDL_Array__init(&opaque->overlay_manager, 32))
        goto fail;
    if (ISDL_Array__init(&opaque->overlay_pool, 32))
        goto fail;

    opaque->egl = IJK_EGL_create();
    if (!opaque->egl)
        goto fail;

    vout->opaque_class = &g_nativewindow_class;
    vout->create_overlay = func_create_overlay;
    vout->free_l = func_free_l;
    vout->display_overlay = func_display_overlay;
    return vout;
    fail:
    func_free_l(vout);
    return NULL;
}

static void SDL_VoutAndroid_SetNativeWindow_l(SDL_Vout * vout, struct EGLNativeWindowType * native_window)
{
    AMCTRACE("%s(%p, %p)\n", __func__, vout, native_window);
    SDL_Vout_Opaque * opaque = vout->opaque;

    if (opaque->native_window == native_window) {
        if (native_window == NULL) {
            // always invalidate buffers, if native_window is changed
//            SDL_VoutAndroid_invalidateAllBuffers_l(vout);
        }
        return;
    }
    IJK_EGL_terminate(opaque->egl);
//    SDL_VoutAndroid_invalidateAllBuffers_l(vout);

//    if (opaque->native_window)
//    //ANativeWindow_release(opaque->native_window);
//        NativeLayerHandle(opaque->native_window, RELEASE_REF);
//
//    if (native_window)
//    //ANativeWindow_acquire(native_window);
//        NativeLayerHandle(native_window, ACQUIRE_REF);
    opaque->native_window = native_window;
    opaque->null_native_window_warned = 0;
}

void SDL_VoutAndroid_SetNativeWindow(SDL_Vout * vout,struct EGLNativeWindowType * native_window)
{
    SDL_LockMutex(vout->mutex);
    SDL_VoutAndroid_SetNativeWindow_l(vout, native_window);
    SDL_UnlockMutex(vout->mutex);
}

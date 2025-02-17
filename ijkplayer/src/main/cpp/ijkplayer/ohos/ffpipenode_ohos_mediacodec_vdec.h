/*
 * ffpipenode_ohos_mediacodec_vdec.h
 *
 * Copyright (C) 2024 Huawei Device Co.,Ltd.
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

#ifndef FFPLAY__FF_FFPIPENODE_OHOS_MEDIACODEC_VDEC_H
#define FFPLAY__FF_FFPIPENODE_OHOS_MEDIACODEC_VDEC_H

extern "C" {
#include "ff_ffplay.h"
}

#include <thread>
#include "ff_ffplay_def.h"
#include "../../ijksdl/ijksdl_vout.h"

enum AVCodecSampleError : int {
    AVCODEC_SAMPLE_ERR_OK = 0,
    AVCODEC_SAMPLE_ERR_ERROR = -1,
};

extern "C" {
IJKFF_Pipenode *ffpipenode_create_video_decoder_from_ohos_mediacodec(FFPlayer *ffp, IJKFF_Pipeline *pipeline,
    SDL_Vout *vout);
}

#endif
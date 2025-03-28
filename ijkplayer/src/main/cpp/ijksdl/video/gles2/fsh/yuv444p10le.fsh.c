/*
 * Copyright (c) 2016 Bilibili
 * copyright (c) 2016 Zhang Rui <bbcallen@gmail.com>
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

#include "../internal.h"

static const char g_shader[] = IJK_GLES_STRING(
    precision highp float;
    varying   highp vec2 vv2_Texcoord;
    uniform         mat3 um3_ColorConversion;
    uniform   lowp  sampler2D us2_SamplerX;
    uniform   lowp  sampler2D us2_SamplerY;
    uniform   lowp  sampler2D us2_SamplerZ;

    void main()
    {
        mediump vec3 yuv_l;
        mediump vec3 yuv_h;
        mediump vec3 yuv;
        lowp    vec3 rgb;

        yuv_l.x = texture2D(us2_SamplerX, vv2_Texcoord).r;
        yuv_h.x = texture2D(us2_SamplerX, vv2_Texcoord).a;
        yuv_l.y = texture2D(us2_SamplerY, vv2_Texcoord).r;
        yuv_h.y = texture2D(us2_SamplerY, vv2_Texcoord).a;
        yuv_l.z = texture2D(us2_SamplerZ, vv2_Texcoord).r;
        yuv_h.z = texture2D(us2_SamplerZ, vv2_Texcoord).a;

        yuv = (yuv_l * 255.0 + yuv_h * 255.0 * 256.0) / (1023.0) - vec3(16.0 / 255.0, 0.5, 0.5);

        rgb = um3_ColorConversion * yuv;
        gl_FragColor = vec4(rgb, 1);
    }
);

const char *IJK_GLES2_getFragmentShader_yuv444p10le()
{
    return g_shader;
}


#ifndef ijkplayer_custom_ffmpeg_log_H
#define ijkplayer_custom_ffmpeg_log_H
#include <libavutil/log.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavfilter/avfilter.h>
#include <libswresample/swresample.h>
#include <libavutil/opt.h>
#include <libavutil/imgutils.h>
#include <libavutil/thread.h>
#include <libavutil/bprint.h>
#include <libswscale/swscale.h>
#include "../ohoslog/ohos_log.h"

void open_custom_ffmpeg_log_print();

#endif //ijkplayer_custom_ffmpeg_log_H

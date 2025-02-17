
#include "custom_ffmpeg_log.h"

#define LINE_SZ 1024
static int av_log_level = AV_LOG_INFO;
static AVMutex mutex = AV_MUTEX_INITIALIZER;
static int flags;

static int get_category(void *ptr){
    AVClass *avc = *(AVClass **) ptr;
    if(    !avc
    || (avc->version&0xFF)<100
    ||  avc->version < (51 << 16 | 59 << 8)
    ||  avc->category >= AV_CLASS_CATEGORY_NB) return AV_CLASS_CATEGORY_NA + 16;

    if(avc->get_category)
        return avc->get_category(ptr) + 16;

    return avc->category + 16;
}

static const char *get_level_str(int level)
{
    switch (level) {
        case AV_LOG_QUIET:
        return "quiet";
        case AV_LOG_DEBUG:
        return "debug";
        case AV_LOG_VERBOSE:
        return "verbose";
        case AV_LOG_INFO:
        return "info";
        case AV_LOG_WARNING:
        return "warning";
        case AV_LOG_ERROR:
        return "error";
        case AV_LOG_FATAL:
        return "fatal";
        case AV_LOG_PANIC:
        return "panic";
        default:
        return "";
    }
}

static void format_line(void *avcl, int level, const char *fmt, va_list vl,
                        struct AVBPrint part[4], int *print_prefix, int type[2])
{
    AVClass* avc = avcl ? *(AVClass **) avcl : NULL;
    av_bprint_init(part+0, 0, AV_BPRINT_SIZE_AUTOMATIC);
    av_bprint_init(part+1, 0, AV_BPRINT_SIZE_AUTOMATIC);
    av_bprint_init(part+2, 0, AV_BPRINT_SIZE_AUTOMATIC);
    av_bprint_init(part+3, 0, 65536);

    if(type) type[0] = type[1] = AV_CLASS_CATEGORY_NA + 16;
    if (*print_prefix && avc) {
        if (avc->parent_log_context_offset) {
            AVClass** parent = *(AVClass ***) (((uint8_t *) avcl) +
                    avc->parent_log_context_offset);
            if (parent && *parent) {
                av_bprintf(part+0, "[%s @ %p] ",
                        (*parent)->item_name(parent), parent);
                if(type) type[0] = get_category(parent);
            }
        }
        av_bprintf(part+1, "[%s @ %p] ",
                avc->item_name(avcl), avcl);
        if(type) type[1] = get_category(avcl);
    }

    if (*print_prefix && (level > AV_LOG_QUIET) && (flags & AV_LOG_PRINT_LEVEL))
        av_bprintf(part+2, "[%s] ", get_level_str(level));

    av_vbprintf(part+3, fmt, vl);

    if(*part[0].str || *part[1].str || *part[2].str || *part[3].str) {
        char lastc = part[3].len && part[3].len <= part[3].size ? part[3].str[part[3].len - 1] : 0;
        *print_prefix = lastc == '\n' || lastc == '\r';
    }
}

void av_log_callback(void* ptr, int level, const char* fmt, va_list vl)
{
    static int print_prefix = 1;
    static int count;
    static char prev[LINE_SZ];
    struct AVBPrint part[4];
    char line[LINE_SZ];
    static int is_atty;
    int type[2];
    unsigned tint = 0;

    if (level >= 0) {
        tint = level & 0xff00;
        level &= 0xff;
    }
    format_line(ptr, level, fmt, vl, part, &print_prefix, type);
    LOGI("ffmpeg-->log_print:%s%s%s%s",part[0].str, part[1].str, part[2].str, part[3].str);
}

void open_custom_ffmpeg_log_print(){
    av_log_set_level(AV_LOG_DEBUG); //设置日志级别
    av_log_set_callback(av_log_callback);  // 设置自定义的日志输出方法
}
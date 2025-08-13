#ifndef ROHYPLAYER_ROHY_METADATA_SHARED_H
#define ROHYPLAYER_ROHY_METADATA_SHARED_H

extern "C" {
#include "libavformat/avformat.h"
}

struct Header {
    const char* key;
    const char* value;
};

struct AVFormatContextDeleter {
    void operator()(AVFormatContext* ctx) const {
        if (ctx) {
            if (!(ctx->oformat->flags & AVFMT_NOFILE)) {
                avio_closep(&ctx->pb);
            }
            avformat_free_context(ctx);
        }
    }
};

#endif //ROHYPLAYER_ROHY_METADATA_SHARED_H

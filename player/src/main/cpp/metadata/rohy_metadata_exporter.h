//
// Created on 2025/8/7.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ROHYPLAYER_ROHY_METADATA_EXPORTER_H
#define ROHYPLAYER_ROHY_METADATA_EXPORTER_H

#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <stdexcept>
#include <cstring>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
}

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

struct AVIOContextDeleter {
    void operator()(AVIOContext* ctx) const {
        avio_closep(&ctx);
    }
};

struct StreamExtractConfig {
    int stream_index = -1;
    std::string output_file;
    std::unique_ptr<AVFormatContext, AVFormatContextDeleter> output_ctx;
    AVStream* out_stream = nullptr;
    std::string final_output_file;
    int packet_count = 0;
};

class RohyMetadataExporter {
public:
    static void extract_multiple_streams(const std::string& input_file, std::vector<StreamExtractConfig>& configs);
};

#endif //ROHYPLAYER_ROHY_METADATA_EXPORTER_H

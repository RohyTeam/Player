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

#include "rohy_metadata_shared.h"

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
    
    bool is_attachment = false;
    FILE* attachment_file = nullptr;
};

class RohyMetadataExporter {
public:
    static void extract_multiple_streams(const std::string& url, std::vector<Header> headers, std::vector<StreamExtractConfig>& configs);
};

#endif //ROHYPLAYER_ROHY_METADATA_EXPORTER_H

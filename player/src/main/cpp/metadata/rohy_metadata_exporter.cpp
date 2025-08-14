#include "rohy_metadata_exporter.h"
#include <hilog/log.h>

const char* get_recommended_subtitle_extension(enum AVCodecID codec_id) {
    switch (codec_id) {
        case AV_CODEC_ID_ASS:
        case AV_CODEC_ID_SSA:
            return "ass";
        case AV_CODEC_ID_SRT:
        case AV_CODEC_ID_SUBRIP:
            return "srt";
        case AV_CODEC_ID_WEBVTT:
            return "vtt";
        case AV_CODEC_ID_MOV_TEXT:
            return "txt";
        case AV_CODEC_ID_HDMV_PGS_SUBTITLE:
            return "sup";
        case AV_CODEC_ID_DVD_SUBTITLE:
            return "sub";
        case AV_CODEC_ID_DVB_SUBTITLE:
            return "dvb";
        default:
            return "mkv";
    }
}

bool format_supports_subtitle_codec(const AVOutputFormat* oformat, enum AVCodecID codec_id) {
    if (avformat_query_codec(oformat, codec_id, FF_COMPLIANCE_NORMAL) > 0) {
        return true;
    }
    
    if (oformat->subtitle_codec == codec_id) {
        return true;
    }
    
    if (oformat->codec_tag) {
        if (av_codec_get_tag(oformat->codec_tag, codec_id) > 0) {
            return true;
        }
    }
    
    return false;
}

void prepare_stream_output(AVFormatContext* input_ctx, StreamExtractConfig& config) {
    AVStream* in_stream = input_ctx->streams[config.stream_index];
    enum AVCodecID codec_id = in_stream->codecpar->codec_id;
    enum AVMediaType media_type = in_stream->codecpar->codec_type;
    
    config.final_output_file = config.output_file;
    bool output_file_modified = false;
    
    if (media_type == AVMEDIA_TYPE_SUBTITLE) {
        const AVOutputFormat* requested_oformat = av_guess_format(nullptr, config.output_file.c_str(), nullptr);
        
        if (requested_oformat && !format_supports_subtitle_codec(requested_oformat, codec_id)) {
            const char* recommended_ext = get_recommended_subtitle_extension(codec_id);
            
            size_t dot_pos = config.final_output_file.find_last_of('.');
            if (dot_pos != std::string::npos) {
                config.final_output_file = config.final_output_file.substr(0, dot_pos);
            }
            config.final_output_file += ".";
            config.final_output_file += recommended_ext;
            
            const char* codec_name = avcodec_get_name(codec_id);
            std::cerr << "警告: 输出格式不支持 '" << codec_name << "' 字幕编解码器\n";
            std::cerr << "      已自动修改输出文件为: " << config.final_output_file << std::endl;
            output_file_modified = true;
        }
    }

    AVFormatContext* raw_output_ctx = nullptr;
    int ret = avformat_alloc_output_context2(&raw_output_ctx, nullptr, nullptr, config.final_output_file.c_str());
    config.output_ctx.reset(raw_output_ctx);
    
    if (!config.output_ctx) {
        if (media_type == AVMEDIA_TYPE_SUBTITLE && !output_file_modified) {
            std::cerr << "尝试使用MKV容器..." << std::endl;
            
            size_t dot_pos = config.final_output_file.find_last_of('.');
            if (dot_pos != std::string::npos) {
                config.final_output_file = config.final_output_file.substr(0, dot_pos);
            }
            config.final_output_file += ".mkv";
            
            ret = avformat_alloc_output_context2(&raw_output_ctx, nullptr, "matroska", config.final_output_file.c_str());
            config.output_ctx.reset(raw_output_ctx);
            
            if (!config.output_ctx) {
                throw std::runtime_error("无法创建MKV输出上下文");
            }
            std::cerr << "已自动修改输出文件为: " << config.final_output_file << std::endl;
        } else {
            throw std::runtime_error("无法创建输出上下文");
        }
    }

    config.out_stream = avformat_new_stream(config.output_ctx.get(), nullptr);
    if (!config.out_stream) {
        throw std::runtime_error("无法创建输出流");
    }

    ret = avcodec_parameters_copy(config.out_stream->codecpar, in_stream->codecpar);
    if (ret < 0) {
        throw std::runtime_error("复制编解码参数失败: " + std::to_string(ret));
    }
    
    config.out_stream->time_base = in_stream->time_base;
    if (config.out_stream->time_base.num == 0 || config.out_stream->time_base.den == 0) {
        config.out_stream->time_base = {1, 1000};
        std::cerr << "警告：使用默认时间基准 " 
                  << config.out_stream->time_base.num << "/"
                  << config.out_stream->time_base.den << std::endl;
    }

    if (!(config.output_ctx->oformat->flags & AVFMT_NOFILE)) {
        ret = avio_open(&config.output_ctx->pb, config.final_output_file.c_str(), AVIO_FLAG_WRITE);
        if (ret < 0) {
            throw std::runtime_error("无法打开输出文件 '" + config.final_output_file + "': " + std::to_string(ret));
        }
    }

    ret = avformat_write_header(config.output_ctx.get(), nullptr);
    if (ret < 0) {
        std::string error_msg = "写入文件头失败: " + std::to_string(ret);
        
        if (media_type == AVMEDIA_TYPE_SUBTITLE) {
            const char* recommended_ext = get_recommended_subtitle_extension(codec_id);
            error_msg += "\n\n字幕提取提示:\n";
            error_msg += "1. 尝试使用推荐的扩展名: .";
            error_msg += recommended_ext;
            error_msg += "\n2. 使用通用容器: .mkv\n";
            error_msg += "3. 如果字幕乱码，尝试手动指定编码:\n";
            error_msg += "   - 在命令行中使用: -metadata:s:s:";
            error_msg += std::to_string(config.stream_index);
            error_msg += " encoding=UTF-8";
        }
        throw std::runtime_error(error_msg);
    }
}

void RohyMetadataExporter::extract_multiple_streams(const std::string& url, std::vector<Header> headers, std::vector<StreamExtractConfig>& configs) {
    AVFormatContext* input_ctx = nullptr;
    AVDictionary* options = nullptr;
    
    av_dict_set(&options, "probesize", "100000000", 0);
    av_dict_set(&options, "analyzeduration", "10000000", 0);
    
    if (!headers.empty()) {
        std::string header_str;
        for (const auto& header : headers) {
            if (header.key && header.value) {
                header_str += std::string(header.key) + ": " + header.value + "\r\n";
            }
        }
        
        if (!header_str.empty()) {
            av_dict_set(&options, "headers", header_str.c_str(), 0);
        }
    }
    
    if (url.find("http://") == 0 || url.find("https://") == 0) {
        av_dict_set(&options, "rw_timeout", "5000000", 0);
        av_dict_set(&options, "reconnect", "1", 0);
        av_dict_set(&options, "reconnect_at_eof", "1", 0);
        av_dict_set(&options, "reconnect_streamed", "1", 0);
    }
    
    int ret = avformat_open_input(&input_ctx, url.c_str(), nullptr, &options);
    if (ret < 0) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "Unable to open input file %{public}s: %{public}s", url.c_str(), std::to_string(ret).c_str());
        throw std::runtime_error("无法打开输入文件 '" + url + "': " + std::to_string(ret));
    }
    
    auto input_ctx_deleter = [&options](AVFormatContext* ctx) { 
        avformat_close_input(&ctx); 
        av_dict_free(&options);
    };
    std::unique_ptr<AVFormatContext, decltype(input_ctx_deleter)> input_ctx_ptr(input_ctx, input_ctx_deleter);

    ret = avformat_find_stream_info(input_ctx, nullptr);
    if (ret < 0) {
        OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "Unable to get stream info: %{public}s", std::to_string(ret).c_str());
        throw std::runtime_error("无法获取流信息: " + std::to_string(ret));
    }

    av_dump_format(input_ctx, 0, url.c_str(), 0);
    
    for (auto& config : configs) {
        if (config.stream_index < 0 || config.stream_index >= input_ctx->nb_streams) {
            OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "Invalid stream index: %{public}s (total: %{public}s)", std::to_string(config.stream_index).c_str(), std::to_string(input_ctx->nb_streams).c_str());
            throw std::runtime_error("无效的流索引 " + std::to_string(config.stream_index) + 
                                     " (总流数: " + std::to_string(input_ctx->nb_streams) + ")");
        }
        
        AVStream* in_stream = input_ctx->streams[config.stream_index];
        const char* type_name = av_get_media_type_string(in_stream->codecpar->codec_type);
        const char* codec_name = avcodec_get_name(in_stream->codecpar->codec_id);
        
        OH_LOG_Print(
            LOG_APP, 
            LOG_ERROR,
            0,
            "ExtractTracks", 
            "Configuring stream #%{public}d: %{public}s (%{public}s) -> %{public}s", 
            config.stream_index,
            type_name,
            codec_name,
            config.output_file.c_str()
        );
    }
    
    for (auto& config : configs) {
        prepare_stream_output(input_ctx, config);
    }

    AVPacket pkt;
    while (true) {
        ret = av_read_frame(input_ctx, &pkt);
        if (ret < 0) {
            if (ret == AVERROR_EOF) {
                break;
            }
            std::cerr << "读取数据包失败: " << ret << "，跳过错误包" << std::endl;
            OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "Failed to read packet: %{public}d, skip", ret);
            continue;
        }
        
        std::unique_ptr<AVPacket, decltype(&av_packet_unref)> packet_guard(&pkt, av_packet_unref);
        
        int stream_index = pkt.stream_index;
        
        for (auto& config : configs) {
            if (config.stream_index == stream_index) {
                AVPacket new_pkt;
                ret = av_packet_ref(&new_pkt, &pkt);
                if (ret < 0) {
                    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "Failed to copy packet: %{public}d", ret);
                    std::cerr << "无法复制数据包: " << ret << std::endl;
                    break;
                }
                
                std::unique_ptr<AVPacket, decltype(&av_packet_unref)> new_pkt_guard(&new_pkt, av_packet_unref);
                
                new_pkt.stream_index = 0;
                av_packet_rescale_ts(&new_pkt, 
                                    input_ctx->streams[stream_index]->time_base, 
                                    config.out_stream->time_base);
                new_pkt.pos = -1;
                
                ret = av_interleaved_write_frame(config.output_ctx.get(), &new_pkt);
                if (ret < 0) {
                    OH_LOG_Print(LOG_APP, LOG_ERROR, 0, "ExtractTracks", "Failed to write packet: %{public}d", ret);
                    std::cerr << "写入数据包失败: " << ret << std::endl;
                } else {
                    config.packet_count++;
                }
                break;
            }
        }
    }

    for (auto& config : configs) {
        av_write_trailer(config.output_ctx.get());
        std::cout << "成功提取流 #" << config.stream_index 
                  << ": " << config.packet_count << " 个数据包到: " 
                  << config.final_output_file << std::endl;
        OH_LOG_Print(
            LOG_APP, 
            LOG_ERROR,
            0,
            "ExtractTracks", 
            "Successfully extracted stream #%{public}d: %{public}d packets -> %{public}s", 
            config.stream_index,
            config.packet_count,
            config.final_output_file.c_str()
        );
    }
}
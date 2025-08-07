#include "rohy_metadata_getter.h"

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
}

struct AVFormatContextDeleter {
    void operator()(AVFormatContext* ctx) const {
        if (ctx) avformat_close_input(&ctx);
    }
};
using AVFormatContextPtr = std::unique_ptr<AVFormatContext, AVFormatContextDeleter>;

struct AVCodecContextDeleter {
    void operator()(AVCodecContext* ctx) const {
        if (ctx) avcodec_free_context(&ctx);
    }
};
using AVCodecContextPtr = std::unique_ptr<AVCodecContext, AVCodecContextDeleter>;

struct AVFrameDeleter {
    void operator()(AVFrame* frame) const {
        if (frame) av_frame_free(&frame);
    }
};
using AVFramePtr = std::unique_ptr<AVFrame, AVFrameDeleter>;

struct AVPacketDeleter {
    void operator()(AVPacket* pkt) const {
        if (pkt) 
            av_packet_free(&pkt);
    }
};
using AVPacketPtr = std::unique_ptr<AVPacket, AVPacketDeleter>;

struct SwsContextDeleter {
    void operator()(SwsContext* sws) const {
        if (sws) 
            sws_freeContext(sws);
    }
};
using SwsContextPtr = std::unique_ptr<SwsContext, SwsContextDeleter>;

namespace {
    int64_t time_base_to_ms(AVRational time_base, int64_t value) {
        return value * 1000 * time_base.num / time_base.den;
    }
    
    std::vector<uint8_t> encode_frame_to_jpeg(const AVFrame* frame) {
        const AVCodec* codec = avcodec_find_encoder(AV_CODEC_ID_MJPEG);
        if (!codec) {
            throw std::runtime_error("JPEG codec not found");
        }
        
        AVCodecContextPtr codec_ctx(avcodec_alloc_context3(codec));
        if (!codec_ctx) {
            throw std::runtime_error("Could not allocate video codec context");
        }
        
        codec_ctx->pix_fmt = AV_PIX_FMT_YUVJ420P;
        codec_ctx->width = frame->width;
        codec_ctx->height = frame->height;
        codec_ctx->time_base = {1, 25};
        codec_ctx->color_range = AVCOL_RANGE_JPEG;
        codec_ctx->bit_rate = 400000;
        codec_ctx->gop_size = 10;
        codec_ctx->max_b_frames = 0;
        codec_ctx->flags |= AV_CODEC_FLAG_QSCALE;
        codec_ctx->global_quality = 3;
        
        if (avcodec_open2(codec_ctx.get(), codec, nullptr) < 0) {
            throw std::runtime_error("Could not open JPEG codec");
        }
        
        AVPacketPtr pkt(av_packet_alloc());
        if (!pkt) {
            throw std::runtime_error("Could not allocate packet");
        }
        
        if (avcodec_send_frame(codec_ctx.get(), frame) < 0) {
            throw std::runtime_error("Error sending frame to encoder");
        }
        
        int ret = avcodec_receive_packet(codec_ctx.get(), pkt.get());
        if (ret < 0) {
            throw std::runtime_error("Error encoding frame");
        }
        
        return {pkt->data, pkt->data + pkt->size};
    }
    
    std::vector<uint8_t> extract_cover_image(AVFormatContext* fmt_ctx, int video_stream_index) {
        AVStream* stream = fmt_ctx->streams[video_stream_index];
        AVCodecParameters* codec_params = stream->codecpar;
        
        const AVCodec* codec = avcodec_find_decoder(codec_params->codec_id);
        if (!codec) {
            throw std::runtime_error("Unsupported codec for cover extraction");
        }
        
        AVCodecContextPtr codec_ctx(avcodec_alloc_context3(codec));
        if (!codec_ctx) {
            throw std::runtime_error("Could not allocate codec context for cover extraction");
        }
        
        if (avcodec_parameters_to_context(codec_ctx.get(), codec_params) < 0) {
            throw std::runtime_error("Could not copy codec parameters for cover extraction");
        }
        
        if (avcodec_open2(codec_ctx.get(), codec, nullptr) < 0) {
            throw std::runtime_error("Could not open decoder for cover extraction");
        }
        
        AVFramePtr frame(av_frame_alloc());
        if (!frame) {
            throw std::runtime_error("Memory allocation failed for cover extraction");
        }
        
        AVPacketPtr pkt(av_packet_alloc());
        if (!pkt) {
            throw std::runtime_error("Memory allocation failed for cover extraction");
        }
        
        if (av_seek_frame(fmt_ctx, video_stream_index, 0, AVSEEK_FLAG_FRAME) < 0) {
            throw std::runtime_error("Could not seek to first frame for cover extraction");
        }
        
        while (av_read_frame(fmt_ctx, pkt.get()) >= 0) {
            if (pkt->stream_index != video_stream_index) {
                av_packet_unref(pkt.get());
                continue;
            }
            
            if (avcodec_send_packet(codec_ctx.get(), pkt.get()) < 0) {
                av_packet_unref(pkt.get());
                continue;
            }
            
            if (avcodec_receive_frame(codec_ctx.get(), frame.get()) >= 0) {
                // 如果已经是JPEG编码，直接使用原始数据
                if (codec_params->codec_id == AV_CODEC_ID_MJPEG) {
                    return {pkt->data, pkt->data + pkt->size};
                }
                
                SwsContextPtr sws_ctx(sws_getContext(
                    frame->width, frame->height, static_cast<AVPixelFormat>(frame->format),
                    frame->width, frame->height, AV_PIX_FMT_YUVJ420P,
                    SWS_BILINEAR, nullptr, nullptr, nullptr
                ));
                
                if (!sws_ctx) {
                    throw std::runtime_error("Could not create scale context for cover extraction");
                }
                
                AVFramePtr yuv_frame(av_frame_alloc());
                if (!yuv_frame) {
                    throw std::runtime_error("Memory allocation failed for cover extraction");
                }
                
                int buffer_size = av_image_get_buffer_size(AV_PIX_FMT_YUVJ420P, 
                                                          frame->width, frame->height, 1);
                std::vector<uint8_t> yuv_buffer(buffer_size);
                
                if (av_image_fill_arrays(yuv_frame->data, yuv_frame->linesize,
                                        yuv_buffer.data(), AV_PIX_FMT_YUVJ420P,
                                        frame->width, frame->height, 1) < 0) {
                    throw std::runtime_error("Failed to fill image arrays for cover extraction");
                }
                
                yuv_frame->width = frame->width;
                yuv_frame->height = frame->height;
                yuv_frame->format = AV_PIX_FMT_YUVJ420P;
                
                sws_scale(sws_ctx.get(),
                         frame->data,
                         frame->linesize,
                         0,
                         frame->height,
                         yuv_frame->data,
                         yuv_frame->linesize);
                
                return encode_frame_to_jpeg(yuv_frame.get());
            }
            
            av_packet_unref(pkt.get());
        }
        
        throw std::runtime_error("No frame found for cover extraction");
    }
    
    int find_cover_track(AVFormatContext* fmt_ctx) {
        for (int i = 0; i < fmt_ctx->nb_streams; i++) {
            AVStream* stream = fmt_ctx->streams[i];
            if (stream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO &&
                stream->codecpar->codec_id == AV_CODEC_ID_MJPEG) {
                return i;
            }
        }
        
        for (int i = 0; i < fmt_ctx->nb_streams; i++) {
            AVStream* stream = fmt_ctx->streams[i];
            if (stream->codecpar->codec_type == AVMEDIA_TYPE_ATTACHMENT) {
                AVDictionaryEntry* mime = av_dict_get(stream->metadata, "mimetype", nullptr, 0);
                if (mime && (strstr(mime->value, "image/jpeg") || 
                             strstr(mime->value, "image/png") ||
                             strstr(mime->value, "image/bmp"))) {
                    return i;
                }
            }
        }
        
        return -1;
    }
}

VideoMetadata RohyMetadataGetter::extract_metadata_and_cover(const std::string& filename) {
    VideoMetadata meta;
    try {
        avformat_network_init();
        
        AVFormatContext* raw_fmt_ctx = nullptr;
        if (avformat_open_input(&raw_fmt_ctx, filename.c_str(), nullptr, nullptr) < 0) {
            meta.set_error(1, "无法打开文件");
            return meta;
        }
        AVFormatContextPtr fmt_ctx(raw_fmt_ctx);
        
        if (avformat_find_stream_info(fmt_ctx.get(), nullptr) < 0) {
            meta.set_error(2, "无法获取流信息");
            return meta;
        }
        
        if (fmt_ctx->duration != AV_NOPTS_VALUE) {
            meta.duration = fmt_ctx->duration * 1000 / AV_TIME_BASE;
        }
        meta.bitrate = fmt_ctx->bit_rate;
        
        int video_stream_idx = av_find_best_stream(fmt_ctx.get(), AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
        if (video_stream_idx < 0) {
            meta.set_error(3, "未找到视频流");
            return meta;
        }
        
        AVStream* video_stream = fmt_ctx->streams[video_stream_idx];
        AVCodecParameters* codecpar = video_stream->codecpar;
        
        meta.width = codecpar->width;
        meta.height = codecpar->height;
        
        meta.hdr = (codecpar->color_range == AVCOL_RANGE_JPEG) || 
                   (codecpar->color_trc == AVCOL_TRC_SMPTE2084) ||
                   (codecpar->color_primaries == AVCOL_PRI_BT2020);
        
        const AVCodec* codec = avcodec_find_decoder(codecpar->codec_id);
        if (codec) {
            meta.codec = codec->name ? codec->name : "";
            meta.codec_full = codec->long_name ? codec->long_name : "";
        }
        
        if (fmt_ctx->nb_chapters > 0) {
            meta.chapters.reserve(fmt_ctx->nb_chapters);
            
            for (int i = 0; i < fmt_ctx->nb_chapters; i++) {
                AVChapter* chapter = fmt_ctx->chapters[i];
                ChapterMetadata cm;
                
                cm.start = time_base_to_ms(chapter->time_base, chapter->start);
                cm.end = time_base_to_ms(chapter->time_base, chapter->end);
                
                AVDictionaryEntry* tag = av_dict_get(chapter->metadata, "title", nullptr, 0);
                if (tag) cm.title = tag->value;
                
                meta.chapters.push_back(std::move(cm));
            }
        }
        
        meta.tracks.reserve(fmt_ctx->nb_streams);
        
        for (int i = 0; i < fmt_ctx->nb_streams; i++) {
            AVStream* stream = fmt_ctx->streams[i];
            TrackMetadata track;
            
            track.index = i;
            if (stream->duration != AV_NOPTS_VALUE) {
                track.duration = time_base_to_ms(stream->time_base, stream->duration);
            }
            
            AVDictionaryEntry* tag = av_dict_get(stream->metadata, "title", nullptr, 0);
            if (tag) track.title = tag->value;
            
            tag = av_dict_get(stream->metadata, "language", nullptr, 0);
            if (tag) track.language = tag->value;
            
            const AVCodec* codec = avcodec_find_decoder(stream->codecpar->codec_id);
            if (codec) {
                track.codec = codec->name ? codec->name : "";
                track.codec_full = codec->long_name ? codec->long_name : "";
            }
            
            switch (stream->codecpar->codec_type) {
                case AVMEDIA_TYPE_VIDEO:
                    track.track_type = TrackType::Video;
                    track.width = stream->codecpar->width;
                    track.height = stream->codecpar->height;
                    track.bitrate = stream->codecpar->bit_rate;
                    break;
                    
                case AVMEDIA_TYPE_AUDIO:
                    track.track_type = TrackType::Audio;
                    track.samplerate = stream->codecpar->sample_rate;
                    track.bitrate = stream->codecpar->bit_rate;
                    break;
                    
                case AVMEDIA_TYPE_SUBTITLE:
                    track.track_type = TrackType::Subtitle;
                    break;
                    
                case AVMEDIA_TYPE_ATTACHMENT:
                    track.track_type = TrackType::Attachment;
                    tag = av_dict_get(stream->metadata, "filename", nullptr, 0);
                    if (tag) track.filename = tag->value;
                    
                    tag = av_dict_get(stream->metadata, "mimetype", nullptr, 0);
                    if (tag) track.mimetype = tag->value;
                    break;
                    
                default:
                    track.track_type = TrackType::Unknown;
                    break;
            }
            
            meta.tracks.push_back(std::move(track));
        }
        
        int cover_stream_index = find_cover_track(fmt_ctx.get());
        
        if (cover_stream_index >= 0) {
            AVPacketPtr pkt(av_packet_alloc());
            
            if (av_read_frame(fmt_ctx.get(), pkt.get()) >= 0 && 
                pkt->stream_index == cover_stream_index) {
                meta.cover.assign(pkt->data, pkt->data + pkt->size);
            }
        }
        
        if (meta.cover.empty()) {
            int video_stream_index = av_find_best_stream(
                fmt_ctx.get(), AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
                
            if (video_stream_index >= 0) {
                meta.cover = extract_cover_image(fmt_ctx.get(), video_stream_index);
            }
        }
        
        meta.success = true;
    }
    catch (const std::exception& e) {
        meta.set_error(100, std::string("处理异常: ") + e.what());
    }
    catch (...) {
        meta.set_error(101, "未知处理异常");
    }
    
    return meta;
}

int RohyMetadataGetter::extract_frame(const std::string& input_path, 
                  const std::string& output_path, 
                  int64_t target_frame) {
    AVFormatContext* raw_fmt_ctx = nullptr;
    if (avformat_open_input(&raw_fmt_ctx, input_path.c_str(), nullptr, nullptr) != 0) {
        fprintf(stderr, "Could not open video file: %s\n", input_path.c_str());
        return -1;
    }
    AVFormatContextPtr fmt_ctx(raw_fmt_ctx);
    
    if (avformat_find_stream_info(fmt_ctx.get(), nullptr) < 0) {
        fprintf(stderr, "Could not find stream information\n");
        return -1;
    }
    
    int video_stream_index = -1;
    for (int i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
            break;
        }
    }
    
    if (video_stream_index == -1) {
        fprintf(stderr, "No video stream found\n");
        return -1;
    }
    
    const AVCodecParameters* codec_params = fmt_ctx->streams[video_stream_index]->codecpar;
    const AVCodec* codec = avcodec_find_decoder(codec_params->codec_id);
    if (!codec) {
        fprintf(stderr, "Unsupported codec\n");
        return -1;
    }
    
    AVCodecContextPtr codec_ctx(avcodec_alloc_context3(codec));
    if (!codec_ctx) {
        fprintf(stderr, "Could not allocate codec context\n");
        return -1;
    }
    
    if (avcodec_parameters_to_context(codec_ctx.get(), codec_params) < 0) {
        fprintf(stderr, "Could not copy codec parameters\n");
        return -1;
    }
    
    if (avcodec_open2(codec_ctx.get(), codec, nullptr) < 0) {
        fprintf(stderr, "Could not open decoder\n");
        return -1;
    }
    
    AVFramePtr frame(av_frame_alloc());
    AVFramePtr yuv_frame(av_frame_alloc());
    AVPacketPtr pkt(av_packet_alloc());
    SwsContextPtr sws_ctx(nullptr);
    std::vector<uint8_t> yuv_buffer;
    
    if (!frame || !yuv_frame || !pkt) {
        fprintf(stderr, "Memory allocation failed\n");
        return -1;
    }
    
    sws_ctx.reset(sws_getContext(
        codec_ctx->width, codec_ctx->height, codec_ctx->pix_fmt,
        codec_ctx->width, codec_ctx->height, AV_PIX_FMT_YUVJ420P,
        SWS_BILINEAR, nullptr, nullptr, nullptr
    ));
    
    if (!sws_ctx) {
        fprintf(stderr, "Could not create scale context\n");
        return -1;
    }
    
    int buffer_size = av_image_get_buffer_size(AV_PIX_FMT_YUVJ420P,
                                             codec_ctx->width,
                                             codec_ctx->height,
                                             1);
    if (buffer_size < 0) {
        fprintf(stderr, "Failed to calculate buffer size\n");
        return -1;
    }
    
    yuv_buffer.resize(buffer_size);
    
    if (av_image_fill_arrays(yuv_frame->data, yuv_frame->linesize,
                           yuv_buffer.data(), AV_PIX_FMT_YUVJ420P,
                           codec_ctx->width, codec_ctx->height, 1) < 0) {
        fprintf(stderr, "Failed to fill image arrays\n");
        return -1;
    }
    
    yuv_frame->width = codec_ctx->width;
    yuv_frame->height = codec_ctx->height;
    yuv_frame->format = AV_PIX_FMT_YUVJ420P;
    
    int64_t current_frame = 0;
    bool frame_found = false;
    
    while (av_read_frame(fmt_ctx.get(), pkt.get()) >= 0) {
        if (pkt->stream_index != video_stream_index) {
            av_packet_unref(pkt.get());
            continue;
        }
        
        if (avcodec_send_packet(codec_ctx.get(), pkt.get()) < 0) {
            fprintf(stderr, "Error sending packet to decoder\n");
            av_packet_unref(pkt.get());
            continue;
        }
        
        while (avcodec_receive_frame(codec_ctx.get(), frame.get()) >= 0) {
            if (current_frame == target_frame) {
                sws_scale(sws_ctx.get(),
                         frame->data,
                         frame->linesize,
                         0,
                         codec_ctx->height,
                         yuv_frame->data,
                         yuv_frame->linesize);
                
                try {
                    auto jpeg_data = encode_frame_to_jpeg(yuv_frame.get());
                    FILE* file = fopen(output_path.c_str(), "wb");
                    if (!file) {
                        fprintf(stderr, "Could not open %s\n", output_path.c_str());
                        return -1;
                    }
                    fwrite(jpeg_data.data(), 1, jpeg_data.size(), file);
                    fclose(file);
                    
                    printf("Successfully saved frame %" PRId64 " as %s\n", target_frame, output_path.c_str());
                    frame_found = true;
                }
                catch (const std::exception& e) {
                    fprintf(stderr, "Error saving frame: %s\n", e.what());
                }
                return frame_found ? 0 : -1;
            }
            current_frame++;
        }
        av_packet_unref(pkt.get());
    }
    
    avcodec_send_packet(codec_ctx.get(), nullptr);
    while (avcodec_receive_frame(codec_ctx.get(), frame.get()) >= 0) {
        if (current_frame == target_frame) {
            sws_scale(sws_ctx.get(),
                     frame->data,
                     frame->linesize,
                     0,
                     codec_ctx->height,
                     yuv_frame->data,
                     yuv_frame->linesize);
            
            try {
                auto jpeg_data = encode_frame_to_jpeg(yuv_frame.get());
                FILE* file = fopen(output_path.c_str(), "wb");
                if (!file) {
                    fprintf(stderr, "Could not open %s\n", output_path.c_str());
                    return -1;
                }
                fwrite(jpeg_data.data(), 1, jpeg_data.size(), file);
                fclose(file);
                
                printf("Successfully saved frame %" PRId64 " as %s\n", target_frame, output_path.c_str());
                frame_found = true;
            }
            catch (const std::exception& e) {
                fprintf(stderr, "Error saving frame: %s\n", e.what());
            }
            return frame_found ? 0 : -1;
        }
        current_frame++;
    }
    
    fprintf(stderr, "Target frame %" PRId64 " not found\n", target_frame);
    return -1;
}
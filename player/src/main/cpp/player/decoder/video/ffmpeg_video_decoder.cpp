#include "ffmpeg_video_decoder.h"

FFmpegVideoDecoder::FFmpegVideoDecoder() = default;

FFmpegVideoDecoder::~FFmpegVideoDecoder() {
    close();
}

bool FFmpegVideoDecoder::open(const std::string& filePath) {
    // 打开媒体文件
    if (avformat_open_input(&formatCtx_, filePath.c_str(), nullptr, nullptr) != 0) {
        return false;
    }
    
    // 获取流信息
    if (avformat_find_stream_info(formatCtx_, nullptr) < 0) {
        return false;
    }
    
    // 查找视频流
    for (unsigned int i = 0; i < formatCtx_->nb_streams; i++) {
        if (formatCtx_->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamIndex_ = i;
            break;
        }
    }
    if (videoStreamIndex_ == -1) return false;
    
    // 获取解码器
    AVCodecParameters* codecPar = formatCtx_->streams[videoStreamIndex_]->codecpar;
    const AVCodec* codec = avcodec_find_decoder(codecPar->codec_id);
    if (!codec) return false;
    
    // 创建解码器上下文
    codecCtx_ = avcodec_alloc_context3(codec);
    if (avcodec_parameters_to_context(codecCtx_, codecPar) < 0) {
        return false;
    }
    
    // 打开解码器
    if (avcodec_open2(codecCtx_, codec, nullptr) < 0) {
        return false;
    }
    
    // 分配帧和包
    frame_ = av_frame_alloc();
    packet_ = av_packet_alloc();
    if (!frame_ || !packet_) return false;
    
    return true;
}

void FFmpegVideoDecoder::close() {
    if (frame_) av_frame_free(&frame_);
    if (packet_) av_packet_free(&packet_);
    if (codecCtx_) avcodec_free_context(&codecCtx_);
    if (formatCtx_) avformat_close_input(&formatCtx_);
    if (swsCtx_) sws_freeContext(swsCtx_);
    if (videoBuffer_) av_free(videoBuffer_);
    
    formatCtx_ = nullptr;
    codecCtx_ = nullptr;
    frame_ = nullptr;
    packet_ = nullptr;
    swsCtx_ = nullptr;
    videoBuffer_ = nullptr;
    bufferSize_ = 0;
}

bool FFmpegVideoDecoder::getNextFrame(uint8_t** data, int* width, int* height, int* linesize) {
    while (av_read_frame(formatCtx_, packet_) >= 0) {
        if (packet_->stream_index == videoStreamIndex_) {
            // 发送数据包到解码器
            int ret = avcodec_send_packet(codecCtx_, packet_);
            av_packet_unref(packet_);
            if (ret < 0) continue;
            
            // 接收解码后的帧
            ret = avcodec_receive_frame(codecCtx_, frame_);
            if (ret == AVERROR(EAGAIN))
                continue;
            if (ret < 0) return false;
            
            // 初始化SWS上下文（第一次调用时）
            if (!swsCtx_) {
                swsCtx_ = sws_getContext(
                    frame_->width, frame_->height, 
                    codecCtx_->pix_fmt,
                    frame_->width, frame_->height,
                    AV_PIX_FMT_RGBA,
                    SWS_BILINEAR, nullptr, nullptr, nullptr
                );
                if (!swsCtx_) return false;
                
                // 分配视频缓冲区
                bufferSize_ = av_image_get_buffer_size(
                    AV_PIX_FMT_RGBA, frame_->width, frame_->height, 1);
                videoBuffer_ = static_cast<uint8_t*>(av_malloc(bufferSize_));
                if (!videoBuffer_) return false;
            }
            
            // 转换帧为RGBA格式
            uint8_t* dstData[1] = { videoBuffer_ };
            int dstLinesize[1] = { frame_->width * 4 };
            sws_scale(swsCtx_, frame_->data, frame_->linesize, 
                      0, frame_->height, dstData, dstLinesize);
            
            *data = videoBuffer_;
            *width = frame_->width;
            *height = frame_->height;
            *linesize = dstLinesize[0];
            
            av_frame_unref(frame_);
            return true;
        }
        av_packet_unref(packet_);
    }
    return false;
}
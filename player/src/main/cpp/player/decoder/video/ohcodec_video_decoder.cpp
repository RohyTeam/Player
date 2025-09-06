#include "ohcodec_video_decoder.h"
#include "utils/rohy_logger.h"

OHCodecVideoDecoder::OHCodecVideoDecoder(const std::string& codec, bool hardware) : _hardware(hardware) {
    OH_AVCapability *capability = OH_AVCodec_GetCapabilityByCategory(codec.c_str(), false, hardware ? HARDWARE : SOFTWARE);
    const char *name = OH_AVCapability_GetName(capability);
    this->_av_codec = OH_VideoDecoder_CreateByName(name);
    
    this->_av_format = std::shared_ptr<OH_AVFormat>(OH_AVFormat_Create(), OH_AVFormat_Destroy);
    if (this->_av_format == nullptr) {
        ROHY_ERROR("OHCodecVideoDecoder", "Failed to create av format");
    }
}

void OHCodecVideoDecoder::init(uint64_t width, uint64_t height) {
    OH_AVFormat_SetIntValue(this->_av_format.get(), OH_MD_KEY_WIDTH, width);
    OH_AVFormat_SetIntValue(this->_av_format.get(), OH_MD_KEY_HEIGHT, height);
    OH_AVFormat_SetIntValue(this->_av_format.get(), OH_MD_KEY_PIXEL_FORMAT, AV_PIXEL_FORMAT_RGBA);
    OH_AVFormat_SetIntValue(this->_av_format.get(), OH_MD_KEY_VIDEO_ENABLE_LOW_LATENCY, 1);
    OH_AVErrCode ret = OH_VideoDecoder_Configure(this->_av_codec, this->_av_format.get());
    if (ret != AV_ERR_OK) {
        ROHY_ERROR("OHCodecVideoDecoder", "Failed to configure av codec and format");
    }
}
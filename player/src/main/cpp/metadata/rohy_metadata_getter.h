#ifndef ROHYPLAYER_ROHY_METADATA_GETTER_H
#define ROHYPLAYER_ROHY_METADATA_GETTER_H

#include "metadata/rohy_metadata_shared.h"
#include <memory>
#include <vector>
#include <string>
#include <cstdint>
#include <stdexcept>

struct ChapterMetadata {
    std::string title;
    int64_t start = 0;
    int64_t end = 0;
};

enum TrackType {
    Unknown = -1,
    Video = 0,
    Audio = 1,
    Subtitle = 2,
    Attachment = 3
};

struct TrackMetadata {
    int index = -1;
    std::string title;
    std::string codec;
    std::string codec_full;
    std::string language;
    
    int width = 0;
    int height = 0;
    int64_t duration = 0;
    double averageFrameRate = -1;
    int bitrate = 0;
    int hdr = -1;
    
    int samplerate = 0;
    
    std::string filename;
    std::string mimetype;
    
    TrackType track_type = TrackType::Unknown;
};

class VideoMetadata {
public:
    int64_t duration = 0;
    int bitrate = 0;
    int width = 0;
    int height = 0;
    double averageFrameRate = -1;
    int hdr = 0; // 0: not hdr, 1: dovi, 2: hdr vivid, 3: hdr 10+, 4: other hdrs
    std::string codec;
    std::string codec_full;
    
    std::vector<ChapterMetadata> chapters;
    std::vector<TrackMetadata> tracks;
    
    std::vector<uint8_t> cover;
    
    bool success = false;
    int error_code = 0;
    std::string error_message;
    
    VideoMetadata() = default;
    
    VideoMetadata(const VideoMetadata&) = delete;
    VideoMetadata& operator=(const VideoMetadata&) = delete;
    
    VideoMetadata(VideoMetadata&&) = default;
    VideoMetadata& operator=(VideoMetadata&&) = default;
    
    void set_error(int code, const std::string& message) {
        success = false;
        error_code = code;
        error_message = message;
    }
};

class RohyMetadataGetter {
public:
    static int extract_frame(const std::string& url, 
                  const std::string& output_path, 
                  int64_t target_frame, 
                  std::vector<Header> headers);
    static VideoMetadata extract_metadata_and_cover(const std::string& url, std::vector<Header> headers);
};

#endif //ROHYPLAYER_ROHY_METADATA_GETTER_H

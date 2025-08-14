#pragma once

#include <cstdint>

#include "segment_data.hpp"
#include <memory>
#include <vector>

namespace Pgs {
    enum class SegmentType {
        PaletteDefinition = 0x14,
        ObjectDefinition = 0x15,
        PresentationComposition = 0x16,
        WindowDefinition = 0x17,
        EndOfDisplaySet = 0x80
    };

    class Segment {
    protected:
        char magicNumber[2] {};
        uint32_t presentationTimestamp;
        uint32_t decodingTimestamp;
        SegmentType segmentType;
        uint16_t segmentSize;
        std::shared_ptr<SegmentData> data;

    public:
        static constexpr uint16_t MIN_BYTE_SIZE = 13u;

        Segment();

        ~Segment();

        static uint16_t getSegmentSize(const char *data, const uint16_t &size) noexcept;

        uint16_t import(const char *inData, const uint32_t &size);

        uint16_t import(const std::vector<char> &inData);

        const char *getMagicNumber() const;

        const uint32_t &getPresentationTimestamp() const;

        const uint32_t &getDecodingTimestamp() const;

        const SegmentType &getSegmentType() const;

        const uint16_t &getSegmentSize() const;

        std::shared_ptr<SegmentData> getData() const;
    };
}

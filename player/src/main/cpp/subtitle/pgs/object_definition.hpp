#pragma once

#include <cstdint>

#include "segment_data.hpp"

#include <memory>
#include <vector>

namespace Pgs {
    enum class SequenceFlag {
        Last = 0x40,
        First = 0x80,
        Only = 0xC0
    };

    class ObjectDefinition final : public SegmentData {
    protected:
        uint16_t id;
        uint8_t version;
        SequenceFlag sequenceFlag;
        uint32_t dataLength;
        uint16_t width;
        uint16_t height;
        std::vector<uint8_t> objectData;

        inline static uint32_t read3Bytes(const uint8_t *data, uint16_t &readPos);

        [[nodiscard]] std::vector<uint8_t> decodeLine(const uint32_t &startPos, const uint32_t &endPos) const;

    public:
        static constexpr uint16_t MIN_BYTE_SIZE = 11u;

        ObjectDefinition();

        uint16_t import(const char *data, const uint16_t &size) override;

        const uint16_t &getId() const noexcept;

        const uint8_t &getVersion() const noexcept;

        const SequenceFlag &getSequenceFlag() const noexcept;

        const uint32_t &getDataLength() const noexcept;

        const uint16_t &getWidth() const noexcept;

        const uint16_t &getHeight() const noexcept;

        const std::vector<uint8_t> &getEncodedObjectData() const noexcept;

        std::vector<std::vector<uint8_t> > getDecodedObjectData() const noexcept;
    };
}

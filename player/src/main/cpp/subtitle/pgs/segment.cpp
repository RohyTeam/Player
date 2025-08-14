#include "segment.hpp"
#include "presentation_composition.hpp"
#include "window_definition.hpp"
#include "palette_definition.hpp"
#include "object_definition.hpp"
#include "pgs_util.hpp"

#include <cstring>

using std::vector;
using std::unique_ptr;
using std::shared_ptr;

using namespace Pgs;

Segment::Segment() {
    this->presentationTimestamp = 0u;
    this->decodingTimestamp = 0u;
    this->segmentType = SegmentType::EndOfDisplaySet;
    this->segmentSize = 0u;
    this->data = std::shared_ptr<SegmentData>();
}

Segment::~Segment() = default;

uint16_t Segment::getSegmentSize(const char *data, const uint16_t &size) noexcept {
    if (size < Segment::MIN_BYTE_SIZE) {
        return 0;
    }

    constexpr uint8_t sizeOffset = 11u;
    uint16_t readPos = 0u;
    const auto segSize = Pgs::read2Bytes(reinterpret_cast<const uint8_t *>(data + sizeOffset), readPos);
    return segSize;
}

uint16_t Segment::import(const char *inData, const uint32_t &size) {
    const auto byteData = reinterpret_cast<const uint8_t *>(inData);

    if (!byteData) {
        throw ImportException("Segment: no import data provided.");
    }

    if (size < Segment::MIN_BYTE_SIZE) {
        throw ImportException("Segment: Not enough data to fill basic Segment.");
    }

    uint16_t readPos = 0u;
    strncpy(this->magicNumber, reinterpret_cast<const char *>(byteData + readPos), 2);
    readPos += 2;
    this->presentationTimestamp = read4Bytes(byteData, readPos);
    this->decodingTimestamp = read4Bytes(byteData, readPos);
    this->segmentType = static_cast<SegmentType>(byteData[readPos]);
    ++readPos;
    this->segmentSize = read2Bytes(byteData, readPos);

    const uint16_t remainingSize = size - readPos;
    switch (this->segmentType) {
        case SegmentType::PaletteDefinition:
            this->data.reset(new PaletteDefinition());
            break;
        case SegmentType::ObjectDefinition:
            this->data.reset(new ObjectDefinition());
            break;
        case SegmentType::PresentationComposition:
            this->data.reset(new PresentationComposition());
            break;
        case SegmentType::WindowDefinition:
            this->data.reset(new WindowDefinition());
            break;
        case SegmentType::EndOfDisplaySet:
            this->data = nullptr;
            break;
        default:
            throw ImportException("Segment: Unexpected SegmentType encountered");
    }

    if (this->segmentType != SegmentType::EndOfDisplaySet) {
        try {
            readPos += this->data->import(inData + readPos, remainingSize);
        } catch ([[maybe_unused]] const ImportException &exception) {
            throw ImportException("Segment: Attempted to import non-existent data.");
        }
    }

    return readPos;
}

uint16_t Segment::import(const vector<char> &inData) {
    return this->import(inData.data(), inData.size());
}

[[maybe_unused]] const char *Segment::getMagicNumber() const {
    return this->magicNumber;
}

const uint32_t &Segment::getPresentationTimestamp() const {
    return this->presentationTimestamp;
}

const uint32_t &Segment::getDecodingTimestamp() const {
    return this->decodingTimestamp;
}

const SegmentType &Segment::getSegmentType() const {
    return this->segmentType;
}

[[maybe_unused]] const uint16_t &Segment::getSegmentSize() const {
    return this->segmentSize;
}

shared_ptr<SegmentData> Segment::getData() const {
    return this->data;
}

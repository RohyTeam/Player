#pragma once

#include "segment_data.hpp"
#include <memory>
#include <vector>

namespace Pgs {
    enum class CompositionState {
        Normal = 0x00,
        AcquisitionPoint = 0x40,
        EpochStart = 0x80
    };

    class CompositionObject {
    protected:
        uint16_t objectID;
        uint8_t windowID;
        bool croppedFlag;
        uint16_t hPos;
        uint16_t vPos;
        uint16_t cropHPos;
        uint16_t cropVPos;
        uint16_t cropWidth;
        uint16_t cropHeight;

    public:
        static constexpr uint16_t MIN_DATA_SIZE = 8u;

        CompositionObject();

        static std::shared_ptr<CompositionObject> create(const char *data, const uint16_t &size, uint16_t &readPos);

        const uint16_t &getObjectID() const;

        const uint8_t &getWindowID() const;

        const bool &getCroppedFlag() const;

        const uint16_t &getHPos() const;

        const uint16_t &getVPos() const;

        const uint16_t &getCropHPos() const;

        const uint16_t &getCropVPos() const;

        const uint16_t &getCropWidth() const;

        const uint16_t &getCropHeight() const;
    };

    class PresentationComposition final : public SegmentData {
    protected:
        uint16_t width;
        uint16_t height;
        uint8_t frameRate;
        uint16_t compositionNumber;
        CompositionState compositionState;
        bool paletteUpdateFlag;
        uint8_t paletteID;
        uint8_t compositionObjectCount;
        std::vector<std::shared_ptr<CompositionObject> > compositionObjects;

    public:
        static constexpr uint16_t MIN_DATA_SIZE = 11u;

        PresentationComposition();

        uint16_t import(const char *data, const uint16_t &size) override;

        const uint16_t &getWidth() const;

        const uint16_t &getHeight() const;

        const uint8_t &getFrameRate() const;

        const uint16_t &getCompositionNumber() const;

        const CompositionState &getCompositionState() const;

        const bool &getPaletteUpdateFlag() const;

        const uint8_t &getPaletteID() const;

        const uint8_t &getCompositionObjectCount() const;

        const std::vector<std::shared_ptr<CompositionObject> > &getCompositionObjects() const;
    };
}

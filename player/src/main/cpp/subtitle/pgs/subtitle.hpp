#pragma once

#include "segment.hpp"
#include "presentation_composition.hpp"
#include "window_definition.hpp"
#include "palette_definition.hpp"
#include "object_definition.hpp"

#include <cstdint>
#include <array>
#include <vector>
#include <memory>
#include <stdexcept>

using std::vector;
using std::array;
using std::shared_ptr;

namespace Pgs {
    class CreateError final : virtual public std::runtime_error {
    public:
        explicit CreateError(const char *msg);

        ~CreateError() noexcept override = default;
    };

    enum class ColorSpace {
        RGBA,
        YCrCb
    };

    class Subtitle {
    protected:
        shared_ptr<PresentationComposition> presentationComposition;

        shared_ptr<WindowDefinition> windowDefinition;

        shared_ptr<PaletteDefinition> paletteDefinition;

        uint8_t numObjectDefinitions;

        array<shared_ptr<ObjectDefinition>, 2> objectDefinitions;

        uint32_t decodingTime;

        uint32_t presentationTime;

        uint16_t streamWidth = 0u;

        uint16_t streamHeight = 0u;

        uint16_t xOffset = 0u;

        uint16_t yOffset = 0u;

        uint16_t width = 0u;

        uint16_t height = 0u;

        void importPcs(const shared_ptr<SegmentData> &segmentData);

        void importWds(const shared_ptr<SegmentData> &segmentData);

        void importOds(const shared_ptr<SegmentData> &segmentData);

        void importEnd(const Segment &segment);

        static uint32_t getSubtitleSize(const char *data, const uint32_t &size);

    public:
        Subtitle();

        ~Subtitle();

        static shared_ptr<Subtitle> create(const char *data, const uint32_t &size, uint32_t &readPos);

        static shared_ptr<Subtitle> create(const std::vector<char> &data, uint32_t &readPos);

        static vector<shared_ptr<Subtitle> > createAll(const char *data, const uint32_t &size);

        Pgs::SegmentType import(const Segment &segment);

        shared_ptr<PresentationComposition> getPcs() const noexcept;

        shared_ptr<WindowDefinition> getWds() const noexcept;

        shared_ptr<PaletteDefinition> getPds() const noexcept;

        shared_ptr<ObjectDefinition> getOds(const uint8_t &index) const noexcept;

        const uint32_t &getPresentationTime() const noexcept;

        uint32_t getPresentationTimeMs() const noexcept;

        const uint32_t &getDecodingTime() const noexcept;

        uint32_t getDecodingTimeMs() const noexcept;

        const uint8_t &getNumObjectDefinitions() const noexcept;

        uint16_t getStreamWidth();

        uint16_t getStreamHeight();

        uint16_t getXOffset();

        uint16_t getYOffset();

        uint16_t getWidth();

        uint16_t getHeight();

        bool containsImage() const noexcept;

        vector<vector<array<uint8_t, 4> > > getImage(const ColorSpace &colorSpace) const;

        inline friend bool operator<(const Subtitle &lhs, const Subtitle &rhs) {
            return lhs.presentationTime < rhs.presentationTime;
        }

        inline friend bool operator>(const Subtitle &lhs, const Subtitle &rhs) {
            return rhs < lhs;
        }

        inline friend bool operator<=(const Subtitle &lhs, const Subtitle &rhs) {
            return !(lhs > rhs);
        }

        inline friend bool operator>=(const Subtitle &lhs, const Subtitle &rhs) {
            return !(lhs < rhs);
        }

        inline friend bool operator==(const Subtitle &lhs, const Subtitle &rhs) {
            return lhs.presentationTime == rhs.presentationTime;
        }

        inline friend bool operator!=(const Subtitle &lhs, const Subtitle &rhs) {
            return !(lhs == rhs);
        }
    };
}

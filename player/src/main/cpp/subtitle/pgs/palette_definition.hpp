#pragma once

#include "segment_data.hpp"

#include <array>
#include <cstdint>
#include <vector>
#include <map>
#include <memory>

namespace Pgs {
    class PaletteEntry {
        constexpr static double Kb = 0.0722f;
        constexpr static double Kr = 0.2126f;
        constexpr static double Kg = 0.7152f;

    protected:
        uint8_t id = 0u;
        uint8_t y = 0u;
        uint8_t cr = 0u;
        uint8_t cb = 0u;
        uint8_t alpha = 0u;

    public:
        static constexpr uint16_t MIN_BYTE_SIZE = 5u;

        PaletteEntry() = default;

        static std::shared_ptr<PaletteEntry> create(const char *data, const uint16_t &size, uint16_t &readPos);

        const uint8_t &getId() const;

        const uint8_t &getY() const;

        const uint8_t &getCr() const;

        const uint8_t &getCb() const;

        const uint8_t &getAlpha() const;

        std::array<uint8_t, 4> getYCrCbA() const;

        uint8_t getRed() const;

        uint8_t getGreen() const;

        uint8_t getBlue() const;

        std::array<uint8_t, 4> getRGBA() const;
    };

    class PaletteDefinition : public SegmentData {
    protected:
        uint8_t id;
        uint8_t version;
        uint8_t numEntries;
        std::map<uint8_t, std::shared_ptr<PaletteEntry> > entries;

    public:
        static constexpr uint16_t MIN_BYTE_SIZE = 3u;

        PaletteDefinition();

        uint16_t import(const char *data, const uint16_t &size) override;

        const uint8_t &getId() const;

        const uint8_t &getVersion() const;

        const uint8_t &getNumEntries() const;

        const std::map<uint8_t, std::shared_ptr<PaletteEntry> > &getEntries() const;
    };
}

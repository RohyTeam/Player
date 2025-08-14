#pragma once

#include <cstdint>

#include "segment_data.hpp"

#include <vector>
#include <memory>

namespace Pgs {
    class WindowObject {
    protected:
        uint8_t id;
        uint16_t hPos;
        uint16_t vPos;
        uint16_t width;
        uint16_t height;

    public:
        static constexpr uint16_t MIN_BYTE_SIZE = 9u;

        WindowObject();

        static std::shared_ptr<WindowObject> create(const char *data, const uint16_t &size, uint16_t &readPos);

        const uint8_t &getId() const;

        const uint16_t &getHPos() const;

        const uint16_t &getVPos() const;

        const uint16_t &getWidth() const;

        const uint16_t &getHeight() const;
    };

    class WindowDefinition : public SegmentData {
    protected:
        uint8_t numWindows;
        std::vector<std::shared_ptr<WindowObject> > windowObjects;

    public:
        static constexpr uint16_t MIN_BYTE_SIZE = 1u;

        WindowDefinition();

        uint16_t import(const char *data, const uint16_t &size) override;

        const uint8_t &getNumWindows() const;

        const std::vector<std::shared_ptr<WindowObject> > &getWindowObjects() const;
    };
}

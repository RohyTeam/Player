#pragma once

#include <cstdint>
#include <stdexcept>

namespace Pgs {
    class SegmentData {
    public:
        SegmentData() = default;

        virtual ~SegmentData() noexcept = default;

        virtual uint16_t import(const char *data, const uint16_t &size) = 0;
    };

    class ImportException final : virtual public std::runtime_error {
    public:
        explicit ImportException(const char *msg);

        ~ImportException() noexcept override = default;
    };
}

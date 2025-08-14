#pragma once

#include <cstdint>

namespace Pgs {

    uint32_t read4Bytes(const uint8_t *data, uint16_t &readPos);
    uint16_t read2Bytes(const uint8_t *data, uint16_t &readPos);

}

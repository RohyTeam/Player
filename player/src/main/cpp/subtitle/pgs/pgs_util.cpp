#include "pgs_util.hpp"

#include <endian.h>

uint32_t Pgs::read4Bytes(const uint8_t *data, uint16_t &readPos) {
    const auto result = static_cast<uint32_t>(data[readPos] << 24u | (data[readPos + 1] << 16u) |
                                        data[readPos + 2] << 8u |
                                        data[readPos + 3]);
    readPos += 4;
    return le32toh(result);
}

uint16_t Pgs::read2Bytes(const uint8_t *data, uint16_t &readPos) {
    const auto result = static_cast<uint16_t>((data[readPos] << 8u) | data[readPos + 1]);
    readPos += 2;
    return le16toh(result);
}

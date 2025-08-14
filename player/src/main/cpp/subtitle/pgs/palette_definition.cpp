#include "palette_definition.hpp"

#include <cstdint>

using std::shared_ptr;
using std::vector;
using std::map;
using std::array;

using namespace Pgs;

shared_ptr<PaletteEntry> PaletteEntry::create(const char *data, const uint16_t &size, uint16_t &readPos) {
    if (!data) {
        throw ImportException("PaletteEntry: no data provided to create method.");
    }

    if (size < PaletteEntry::MIN_BYTE_SIZE) {
        throw ImportException("PaletteEntry: Insufficient data provided to successfully complete creation.");
    }

    auto paletteEntry = std::make_shared<PaletteEntry>();

    const auto byteData = reinterpret_cast<const uint8_t *>(data);

    paletteEntry->id = byteData[readPos];
    ++readPos;
    paletteEntry->y = byteData[readPos];
    ++readPos;
    paletteEntry->cr = byteData[readPos];
    ++readPos;
    paletteEntry->cb = byteData[readPos];
    ++readPos;
    paletteEntry->alpha = byteData[readPos];
    ++readPos;

    return paletteEntry;
}

const uint8_t &PaletteEntry::getId() const {
    return this->id;
}

const uint8_t &PaletteEntry::getY() const {
    return this->y;
}

const uint8_t &PaletteEntry::getCr() const {
    return this->cr;
}

const uint8_t &PaletteEntry::getCb() const {
    return this->cb;
}

const uint8_t &PaletteEntry::getAlpha() const {
    return this->alpha;
}

array<uint8_t, 4> PaletteEntry::getYCrCbA() const {
    const array<uint8_t, 4> color = {this->y, this->cr, this->cb, this->alpha};
    return color;
}

uint8_t PaletteEntry::getRed() const {
    const double yPrime = static_cast<double>(this->y) / UINT8_MAX;
    const double vNorm = (static_cast<double>(this->cr) / 255.0f) - 0.5f;
    const double red = yPrime + (vNorm * (2 - 2 * Kr));
    return static_cast<uint8_t>(red * UINT8_MAX);
}

uint8_t PaletteEntry::getGreen() const {
    const double yPrime = static_cast<double>(this->y) / UINT8_MAX;
    const double uNorm = (static_cast<double>(this->cr) / 255.0f) - 0.5f;
    const double vNorm = (static_cast<double>(this->cr) / 255.0f) - 0.5f;
    const double green = yPrime + (uNorm * (-1 * (Kb / Kg) * (2 - 2 * Kb))) + (vNorm * (-1 * (Kr / Kg) * (2 - 2 * Kr)));
    return static_cast<uint8_t>(green * UINT8_MAX);
}

uint8_t PaletteEntry::getBlue() const {
    const double yPrime = static_cast<double>(this->y) / UINT8_MAX;
    const double uNorm = (static_cast<double>(this->cr) / 255.0f) - 0.5f;
    const double blue = yPrime + (uNorm * (2 - 2 * Kb));
    return static_cast<uint8_t>(blue * UINT8_MAX);
}

array<uint8_t, 4> PaletteEntry::getRGBA() const {
    const array<uint8_t, 4> color = {this->getRed(), this->getGreen(), this->getBlue(), this->alpha};
    return color;
}

PaletteDefinition::PaletteDefinition() : SegmentData() {
    this->id = 0u;
    this->version = 0u;
    this->numEntries = 0u;
    this->entries = map<uint8_t, shared_ptr<PaletteEntry> >();
}

uint16_t PaletteDefinition::import(const char *data, const uint16_t &size) {
    if (!data) {
        throw ImportException("PaletteDefinition: no data provided to import method.");
    }

    if (size < MIN_BYTE_SIZE) {
        throw ImportException("PaletteDefinition: Insufficient data provided to successfully complete import.");
    }

    const auto byteData = reinterpret_cast<const uint8_t *>(data);
    uint16_t readPos = 0u;
    this->id = byteData[readPos];
    ++readPos;
    this->version = byteData[readPos];
    ++readPos;

    uint16_t remainingSize = size - readPos;

    this->numEntries = remainingSize / PaletteEntry::MIN_BYTE_SIZE;

    for (uint8_t i = 0; i < this->numEntries; ++i) {
        auto entry = PaletteEntry::create(data, remainingSize, readPos);
        this->entries.insert(std::make_pair(entry->getId(), entry));
        remainingSize = size - readPos;
    }

    return readPos;
}

const uint8_t &PaletteDefinition::getId() const {
    return this->id;
}

const uint8_t &PaletteDefinition::getVersion() const {
    return this->version;
}

const uint8_t &PaletteDefinition::getNumEntries() const {
    return this->numEntries;
}

const map<uint8_t, shared_ptr<PaletteEntry> > &PaletteDefinition::getEntries() const {
    return this->entries;
}

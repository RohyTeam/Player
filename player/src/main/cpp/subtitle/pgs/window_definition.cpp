#include "window_definition.hpp"
#include "pgs_util.hpp"

extern "C" {
#include <endian.h>
}

using std::shared_ptr;
using std::vector;

using namespace Pgs;

WindowObject::WindowObject() {
    this->id = 0u;
    this->hPos = 0u;
    this->vPos = 0u;
    this->width = 0u;
    this->height = 0u;
}

shared_ptr<WindowObject> WindowObject::create(const char *data, const uint16_t &size, uint16_t &readPos) {
    if (!data) {
        throw ImportException("WindowObject: did not receive input data.");
    }

    if (size < MIN_BYTE_SIZE) {
        throw ImportException("WindowObject: Not enough data to create basic structure.");
    }

    auto window = std::make_shared<WindowObject>();

    const auto byteData = reinterpret_cast<const uint8_t *>(data);
    window->id = byteData[readPos];
    ++readPos;
    window->hPos = be16toh(read2Bytes(byteData, readPos));
    window->vPos = be16toh(read2Bytes(byteData, readPos));
    window->width = be16toh(read2Bytes(byteData, readPos));
    window->height = be16toh(read2Bytes(byteData, readPos));

    return window;
}

const uint8_t &WindowObject::getId() const {
    return this->id;
}

const uint16_t &WindowObject::getHPos() const {
    return this->hPos;
}

const uint16_t &WindowObject::getVPos() const {
    return this->vPos;
}

const uint16_t &WindowObject::getWidth() const {
    return this->width;
}

const uint16_t &WindowObject::getHeight() const {
    return this->height;
}


WindowDefinition::WindowDefinition() {
    this->numWindows = 0u;
    this->windowObjects = vector<shared_ptr<WindowObject> >();
}

uint16_t WindowDefinition::import(const char *data, const uint16_t &size) {
    if (!data) {
        throw ImportException("WindowDefinition: did not receive input data.");
    }

    if (size < WindowDefinition::MIN_BYTE_SIZE) {
        throw ImportException("WindowDefinition: Not enough data to import basic structure.");
    }

    const auto byteData = reinterpret_cast<const uint8_t *>(data);

    uint16_t readPos = 0u;
    this->numWindows = byteData[readPos];

    uint16_t remainingSize = size - readPos;
    if (remainingSize < this->numWindows * WindowObject::MIN_BYTE_SIZE) {
        throw ImportException("WindowDefinition: Not enough data to import all CompositionObjects.");
    }

    this->windowObjects.reserve(this->numWindows);
    for (uint8_t i = 0; i < this->numWindows; ++i) {
        this->windowObjects.push_back(WindowObject::create(data, remainingSize, readPos));
        remainingSize = size - readPos;
    }

    ++readPos;

    return readPos;
}

const uint8_t &WindowDefinition::getNumWindows() const {
    return this->numWindows;
}

const vector<shared_ptr<WindowObject> > &WindowDefinition::getWindowObjects() const {
    return this->windowObjects;
}

#include "pgs_util.hpp"

#include "presentation_composition.hpp"

using std::shared_ptr;
using std::vector;


using namespace Pgs;

CompositionObject::CompositionObject() {
    this->objectID = 0;
    this->windowID = 0;
    this->croppedFlag = false;
    this->hPos = 0;
    this->vPos = 0u;
    this->cropHPos = 0u;
    this->cropVPos = 0u;
    this->cropWidth = 0u;
    this->cropHeight = 0;
}

shared_ptr<CompositionObject> CompositionObject::create(const char *data, const uint16_t &size, uint16_t &readPos) {
    if (size < MIN_DATA_SIZE) {
        throw ImportException("CompositionObject: Not enough data to create basic structure.");
    }

    auto composition = std::make_shared<CompositionObject>();

    const auto *byteData = reinterpret_cast<const uint8_t *>(data);
    composition->objectID = read2Bytes(byteData, readPos);
    composition->windowID = byteData[readPos];
    ++readPos;
    composition->croppedFlag = (byteData[readPos] == 0x40);
    ++readPos;
    composition->hPos = read2Bytes(byteData, readPos);
    composition->vPos = read2Bytes(byteData, readPos);

    if (composition->croppedFlag) {
        composition->cropHPos = read2Bytes(byteData, readPos);
        composition->cropVPos = read2Bytes(byteData, readPos);
        composition->cropWidth = read2Bytes(byteData, readPos);
        composition->cropHeight = read2Bytes(byteData, readPos);
    } else {
        composition->cropHPos = 0u;
        composition->cropVPos = 0u;
        composition->cropWidth = 0u;
        composition->cropHeight = 0u;
    }

    return composition;
}

const uint16_t &CompositionObject::getObjectID() const {
    return this->objectID;
}

const uint8_t &CompositionObject::getWindowID() const {
    return this->windowID;
}

const bool &CompositionObject::getCroppedFlag() const {
    return this->croppedFlag;
}

const uint16_t &CompositionObject::getHPos() const {
    return this->hPos;
}

const uint16_t &CompositionObject::getVPos() const {
    return this->vPos;
}

const uint16_t &CompositionObject::getCropHPos() const {
    return this->cropHPos;
}

const uint16_t &CompositionObject::getCropVPos() const {
    return this->cropVPos;
}

const uint16_t &CompositionObject::getCropWidth() const {
    return this->cropWidth;
}

const uint16_t &CompositionObject::getCropHeight() const {
    return this->cropHeight;
}

PresentationComposition::PresentationComposition() : SegmentData() {
    this->width = 0u;
    this->height = 0u;
    this->frameRate = 0u;
    this->compositionNumber = 0u;
    this->compositionState = CompositionState::EpochStart;
    this->paletteUpdateFlag = false;
    this->paletteID = 0u;
    this->compositionObjectCount = 0u;
    this->compositionObjects = vector<shared_ptr<CompositionObject> >();
}

uint16_t PresentationComposition::import(const char *data, const uint16_t &size) {
    if (size < MIN_DATA_SIZE) {
        throw ImportException("PresentationComposition: Not enough data to import basic structure.");
    }

    const auto *byteData = reinterpret_cast<const uint8_t *>(data);

    this->compositionObjects.clear();

    uint16_t readPos = 0u;
    this->width = read2Bytes(byteData, readPos);
    this->height = read2Bytes(byteData, readPos);
    this->frameRate = byteData[readPos];
    ++readPos;
    this->compositionNumber = read2Bytes(byteData, readPos);
    this->compositionState = CompositionState(byteData[readPos]);
    ++readPos;
    this->paletteUpdateFlag = (byteData[readPos] == 0x80);
    ++readPos;
    this->paletteID = byteData[readPos];
    ++readPos;
    this->compositionObjectCount = byteData[readPos];
    ++readPos;

    uint16_t remainingSize = size - readPos;
    if (remainingSize < CompositionObject::MIN_DATA_SIZE * this->compositionObjectCount) {
        throw ImportException("PresentationComposition: Not enough data to import all CompositionObjects.");
    }

    this->compositionObjects.reserve(this->compositionObjectCount);
    for (uint8_t i = 0u; i < this->compositionObjectCount; ++i) {
        this->compositionObjects.push_back(CompositionObject::create(data, remainingSize, readPos));
        remainingSize = size - readPos;
    }

    return readPos;
}

const uint16_t &PresentationComposition::getWidth() const {
    return this->width;
}

const uint16_t &PresentationComposition::getHeight() const {
    return this->height;
}

const uint8_t &PresentationComposition::getFrameRate() const {
    return this->frameRate;
}

const uint16_t &PresentationComposition::getCompositionNumber() const {
    return this->compositionNumber;
}

const CompositionState &PresentationComposition::getCompositionState() const {
    return this->compositionState;
}

const bool &PresentationComposition::getPaletteUpdateFlag() const {
    return this->paletteUpdateFlag;
}

const uint8_t &PresentationComposition::getPaletteID() const {
    return this->paletteID;
}

const uint8_t &PresentationComposition::getCompositionObjectCount() const {
    return this->compositionObjectCount;
}

const vector<shared_ptr<CompositionObject> > &PresentationComposition::getCompositionObjects() const {
    return this->compositionObjects;
}

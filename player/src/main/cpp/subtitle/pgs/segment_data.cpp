#include "segment_data.hpp"

using namespace Pgs;

ImportException::ImportException(const char *msg) : std::runtime_error(msg) {
}

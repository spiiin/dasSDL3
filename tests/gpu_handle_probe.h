#pragma once
#include "generated/gpu_handle_types.h"

namespace sdl3_test {
// Test both directions of the native distinct ABI, including the upper 32 bits.
inline GpuBufferHandle gpu_handle_echo(GpuBufferHandle value) { return value; }
}

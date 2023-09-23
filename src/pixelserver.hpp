#pragma once

#include <cstdint>

namespace pixelserver
{
void setup(const int width, const int height);
void send(uint32_t *pixels);
} // namespace pixelserver

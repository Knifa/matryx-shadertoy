#pragma once

#include <cstdint>
#include <vector>

namespace pixelserver
{
void setup(const int width, const int height);
void send(uint32_t *pixels);
void sendLayers(uint32_t *pixels, const int count);
} // namespace pixelserver

#pragma once

#include <cstdint>
#include <string>

namespace pixelserver {
void setup(const int width, const int height, const std::string &matryxEndpoint,
           const std::string &layersEndpoint, const std::string &outputEndpoint);

void send(uint32_t *pixels);
void sendLayers(uint32_t *pixels, const int count);
} // namespace pixelserver

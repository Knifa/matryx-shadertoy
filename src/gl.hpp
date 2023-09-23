#pragma once

#include <glad/egl.h>
#include <glad/gles2.h>

#include <filesystem>
#include <string>

namespace gl
{
const int width = 320;
const int height = 192;

int setup();
void drawPlane();

std::string getShaderSource(std::filesystem::path path);
GLuint getVertexShader(std::filesystem::path filename);
} // namespace gl

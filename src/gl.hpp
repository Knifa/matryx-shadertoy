#pragma once

#include <glad/egl.h>
#include <glad/gles2.h>

#include <filesystem>
#include <string>

namespace gl {
extern int width;
extern int height;

int setup(int width, int height);
void drawPlane();

std::string getShaderSource(std::filesystem::path path);
GLuint getVertexShader(std::filesystem::path filename);
} // namespace gl

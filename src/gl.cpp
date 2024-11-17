#include "gl.hpp"

#include <fstream>

#include <plog/Log.h>

static const GLfloat fullPlane[] = {-1.0f, -1.0f, 0.0f, 1.0f, -1.0f, +1.0f, 0.0f, 1.0f,
                                    +1.0f, -1.0f, 0.0f, 1.0f, +1.0f, +1.0f, 0.0f, 1.0f};

static GLuint planeVbo;

namespace gl {
int width;
int height;

namespace {
  static void createPlane();
}

int setup(int width, int height) {
  gl::width = width;
  gl::height = height;

  if (gladLoaderLoadEGL(NULL) == 0) {
    PLOG_FATAL << "Failed to load EGL";
    return 1;
  }

  EGLDeviceEXT devices[1];
  EGLint numDevices;
  if (!eglQueryDevicesEXT(1, devices, &numDevices)) {
    PLOG_FATAL << "Failed to query EGL devices";

    return 1;
  }

  EGLDisplay display = eglGetPlatformDisplayEXT(EGL_PLATFORM_DEVICE_EXT, devices[0], NULL);
  if (display == EGL_NO_DISPLAY) {
    PLOG_FATAL << "Failed to get EGL display";

    return 1;
  }

  if (!eglInitialize(display, NULL, NULL)) {
    PLOG_FATAL << "Failed to initialize EGL";

    return 1;
  }

  EGLint configAttribs[] = {EGL_SURFACE_TYPE,
                            EGL_PBUFFER_BIT,
                            EGL_RENDERABLE_TYPE,
                            EGL_OPENGL_ES2_BIT,
                            EGL_RED_SIZE,
                            8,
                            EGL_GREEN_SIZE,
                            8,
                            EGL_BLUE_SIZE,
                            8,
                            EGL_ALPHA_SIZE,
                            8,
                            EGL_NONE};

  EGLConfig config;
  EGLint numConfigs;
  if (!eglChooseConfig(display, configAttribs, &config, 1, &numConfigs)) {
    PLOG_FATAL << "Failed to choose EGL config";

    return 1;
  }

  EGLint surfaceAttribs[] = {EGL_WIDTH, gl::width, EGL_HEIGHT, gl::height, EGL_NONE};

  EGLSurface surface = eglCreatePbufferSurface(display, config, surfaceAttribs);
  if (surface == EGL_NO_SURFACE) {
    PLOG_FATAL << "Failed to create EGL surface";

    return 1;
  }

  EGLint contextAttribs[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};

  EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttribs);
  if (context == EGL_NO_CONTEXT) {
    PLOG_FATAL << "Failed to create EGL context";

    return 1;
  }

  if (!eglMakeCurrent(display, surface, surface, context)) {
    PLOG_FATAL << "Failed to make EGL context current";

    return 1;
  }

  if (gladLoaderLoadGLES2() == 0) {
    PLOG_FATAL << "Failed to load OpenGL ES 2.0 functions";
    return 1;
  }

  PLOG_DEBUG << "GL_VENDOR: " << glGetString(GL_VENDOR);
  PLOG_DEBUG << "GL_RENDERER: " << glGetString(GL_RENDERER);
  PLOG_DEBUG << "GL_VERSION: " << glGetString(GL_VERSION);

  glViewport(0, 0, gl::width, gl::height);
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

  createPlane();

  return 0;
}

void drawPlane() {
  glBindBuffer(GL_ARRAY_BUFFER, planeVbo);
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, 0);

  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

std::string getShaderSource(std::filesystem::path path) {
  if (!std::filesystem::exists(path)) {
    PLOG_FATAL << "Shader does not exist: " << path;
    throw;
  }

  std::ifstream file(path);
  std::string source((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());

  return source;
}

GLuint getVertexShader(std::filesystem::path filename) {
  if (!std::filesystem::exists(filename)) {
    PLOG_FATAL << "Vertex shader does not exist: " << filename;
    throw;
  }

  GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
  if (vertexShader == 0) {
    PLOG_FATAL << "Failed to create vertex shader";
    throw;
  }

  std::string vertexShaderSource = getShaderSource(filename);
  const char *vertexShaderSources[] = {vertexShaderSource.c_str()};

  glShaderSource(vertexShader, 1, vertexShaderSources, NULL);
  glCompileShader(vertexShader);

  GLint vertexShaderCompiled;
  glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &vertexShaderCompiled);

  if (vertexShaderCompiled == GL_FALSE) {
    PLOG_FATAL << "Failed to compile vertex shader";

    GLint logLength;
    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);

    if (logLength > 0) {
      char *log = new char[logLength];
      glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
      PLOG_FATAL << log;
      delete[] log;
    }

    throw;
  }

  return vertexShader;
}

namespace {
  void createPlane() {
    glGenBuffers(1, &planeVbo);
    glBindBuffer(GL_ARRAY_BUFFER, planeVbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(fullPlane), fullPlane, GL_STATIC_DRAW);
  }
} // namespace
} // namespace gl

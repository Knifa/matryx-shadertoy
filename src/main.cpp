#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <memory>
#include <regex>
#include <string>
#include <thread>
#include <vector>

#include <glad/egl.h>
#include <glad/gles2.h>

#include <argparse/argparse.hpp>
#include <zmq.hpp>

#include "ansi.hpp"
#include "gl.hpp"
#include "pixelserver.hpp"
#include "timer.hpp"

struct ShaderLocation {
  std::string name;
  int startingLine;
};

class ShaderErrorParser {
private:
  std::vector<ShaderLocation> shaderLocations;

public:
  ShaderErrorParser() : shaderLocations() {}
  ShaderErrorParser(std::vector<ShaderLocation> shaderLocations)
      : shaderLocations(shaderLocations) {}

  void parse(const std::string_view error) {
    if (shaderLocations.size() == 0) {
      std::cerr << error << std::endl;
      return;
    }

    std::vector<std::string_view> lines;
    std::string_view lineView = error;
    while (true) {
      auto newlinePos = lineView.find('\n');
      if (newlinePos == std::string::npos) {
        lines.push_back(lineView);
        break;
      }

      lines.push_back(lineView.substr(0, newlinePos));
      lineView = lineView.substr(newlinePos + 1);
    }

    for (auto &line : lines) {
      auto colonPos = line.find(':');
      if (colonPos == std::string::npos) {
        continue;
      }

      auto messagePos = line.find(':', colonPos + 1);
      if (messagePos == std::string::npos) {
        continue;
      }

      auto lineNumber = std::stoi(std::string(line.substr(colonPos + 1))) - 1;
      auto shaderLocation = std::find_if(shaderLocations.rbegin(), shaderLocations.rend(),
                                         [lineNumber](ShaderLocation &shaderLocation) {
                                           return shaderLocation.startingLine <= lineNumber;
                                         });

      auto shaderName = shaderLocation->name;
      auto shaderLine = lineNumber - shaderLocation->startingLine + 1;

      std::string errorOut = shaderName + ":" + std::to_string(shaderLine) + ":" +
                             std::string(line.substr(messagePos + 1));

      std::cerr << errorOut << std::endl;
    }
  }
};

enum class ShaderDataType {
  UintVec4,
  Float,
  FloatVec4,
};

class BaseShader {
public:
  GLuint program;
  GLuint fragmentShader;

  BaseShader(GLuint vertexShader, std::string_view fragmentShaderSource,
             ShaderErrorParser &errorParser) {
    program = glCreateProgram();

    if (program == 0) {
      std::cerr << "Failed to create shader program" << std::endl;
      throw;
    }

    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    if (fragmentShader == 0) {
      std::cerr << "Failed to create fragment shader" << std::endl;
      throw;
    }

    const char *fragmentShaders[] = {fragmentShaderSource.data()};
    glShaderSource(fragmentShader, 1, fragmentShaders, NULL);
    glCompileShader(fragmentShader);

    GLint shaderCompiled;
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &shaderCompiled);
    if (shaderCompiled == GL_FALSE) {
      std::cerr << "Failed to compile fragment shader" << std::endl;

      GLint logLength;
      glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &logLength);

      char *log = new char[logLength];
      glGetShaderInfoLog(fragmentShader, logLength, &logLength, log);
      errorParser.parse(log);

      delete[] log;
      throw std::runtime_error("Failed to compile fragment shader");
    }

    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);

    glBindAttribLocation(program, 0, "a_position");

    glLinkProgram(program);

    GLint programLinked;
    glGetProgramiv(program, GL_LINK_STATUS, &programLinked);
    if (programLinked == GL_FALSE) {
      std::cerr << "Failed to link program" << std::endl;
      GLint logLength;
      glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);

      if (logLength > 0) {
        char *log = new char[logLength];
        glGetProgramInfoLog(program, logLength, &logLength, log);
        std::cerr << log << std::endl;

        delete[] log;
      }

      throw std::runtime_error("Failed to link program");
    }
  }

  ~BaseShader() {
    glDeleteShader(fragmentShader);
    glDeleteProgram(program);
  }
};

class Shader : public BaseShader {
public:
  const std::filesystem::path path;
  const ShaderDataType type;

  GLint timeLoc;
  GLint timeDeltaLoc;
  std::vector<GLint> buffLocs;
  GLint buffPrevLoc;
  GLint frameLoc;

  Shader(std::filesystem::path path, ShaderDataType type, GLuint vertexShader,
         std::string_view fragmentShaderSource, int bufferCount, ShaderErrorParser &errorParser)
      : BaseShader(vertexShader, fragmentShaderSource, errorParser), path(path), type(type) {
    timeLoc = glGetUniformLocation(program, "time");
    timeDeltaLoc = glGetUniformLocation(program, "timeDelta");
    frameLoc = glGetUniformLocation(program, "frame");
    buffPrevLoc = glGetUniformLocation(program, "buffPrev");

    buffLocs.resize(bufferCount);
    for (auto i = 0; i < bufferCount; i++) {
      buffLocs[i] = glGetUniformLocation(program, ("_buff" + std::to_string(i)).c_str());
    }
  }
};

class BufferManager {
public:
  std::vector<GLuint> fronts;
  std::vector<GLuint> backs;

  BufferManager() : fronts(), backs() {}

  void add(ShaderDataType type) {
    GLuint front;
    GLuint back;

    GLint glInternalFormat = 0;
    GLenum glFormat = 0;
    GLenum glType = 0;

    switch (type) {
    case ShaderDataType::UintVec4:
      glInternalFormat = GL_RGBA8;
      glFormat = GL_RGBA;
      glType = GL_UNSIGNED_BYTE;
      break;
    case ShaderDataType::Float:
      glInternalFormat = GL_R32F;
      glFormat = GL_RED;
      glType = GL_FLOAT;
      break;
    case ShaderDataType::FloatVec4:
      glInternalFormat = GL_RGBA32F;
      glFormat = GL_RGBA;
      glType = GL_FLOAT;
      break;
    }

    front = 0;
    back = 0;

    for (auto tex : {&front, &back}) {
      glGenTextures(1, tex);
      glBindTexture(GL_TEXTURE_2D, *tex);
      glTexImage2D(GL_TEXTURE_2D, 0, glInternalFormat, gl::width, gl::height, 0, glFormat, glType,
                   NULL);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

      if (glGetError() != GL_NO_ERROR) {
        std::cerr << "Failed to create framebuffer texture" << std::endl;
        throw std::runtime_error("Failed to create framebuffer texture");
      }
    }

    fronts.push_back(front);
    backs.push_back(back);
  }

  void clear() {
    for (auto &front : fronts) {
      glDeleteTextures(1, &front);
    }

    for (auto &back : backs) {
      glDeleteTextures(1, &back);
    }

    fronts.clear();
    backs.clear();
  }

  void swap(int index) { std::swap(fronts[index], backs[index]); }
};

class ShaderManager {
private:
  std::filesystem::path shadersBaseDirPath;
  std::string shaderName;

public:
  std::vector<std::filesystem::path> loadedPaths;
  std::vector<std::unique_ptr<Shader>> shaderObjects;

  ShaderManager(std::filesystem::path shadersBaseDirPath, std::string shaderName)
      : shadersBaseDirPath(shadersBaseDirPath), shaderName(shaderName) {}

  void load() {
    int preludeLineCounter = 0;
    std::string preludeSource;
    std::vector<ShaderLocation> preludeLocations;
    std::vector<std::unique_ptr<Shader>> newShaderObjects;
    std::vector<std::filesystem::path> newLoadedPaths;

    std::filesystem::path preludeDirPath = shadersBaseDirPath / "prelude";
    std::filesystem::path shaderDirPath = shadersBaseDirPath / shaderName;

    std::cout << "Shaders base dir: " << shadersBaseDirPath << std::endl;
    std::cout << "Prelude dir: " << preludeDirPath << std::endl;
    std::cout << "Shader dir: " << shaderDirPath << std::endl;

    auto vertexShader = gl::getVertexShader(shadersBaseDirPath / "vertex.glsl");

    std::vector<std::filesystem::path> preludeFiles;
    std::vector<std::filesystem::path> shaderFiles;
    std::vector<std::filesystem::path> shaderPreludeFiles;

    for (const auto &entry : std::filesystem::directory_iterator(preludeDirPath)) {
      auto path = entry.path();

      if (path.extension() != ".glsl") {
        continue;
      }

      std::cout << "PRELUDE: Found " << path << std::endl;
      preludeFiles.push_back(path);
    }

    for (const auto &entry : std::filesystem::directory_iterator(shaderDirPath)) {
      auto path = entry.path();

      if (path.extension() != ".glsl") {
        continue;
      }

      if (path.filename().string().starts_with("prelude")) {
        std::cout << "SHADER PRELUDE: Found" << path << std::endl;
        shaderPreludeFiles.push_back(path);
      } else {
        std::cout << "SHADER: Found " << path << std::endl;
        shaderFiles.push_back(path);
      }
    }

    std::sort(preludeFiles.begin(), preludeFiles.end());
    std::sort(shaderPreludeFiles.begin(), shaderPreludeFiles.end());
    std::sort(shaderFiles.begin(), shaderFiles.end());

    newLoadedPaths.insert(newLoadedPaths.end(), preludeFiles.begin(), preludeFiles.end());
    newLoadedPaths.insert(newLoadedPaths.end(), shaderPreludeFiles.begin(),
                          shaderPreludeFiles.end());
    newLoadedPaths.insert(newLoadedPaths.end(), shaderFiles.begin(), shaderFiles.end());

    addPreludeFiles(preludeSource, preludeLocations, preludeLineCounter, preludeFiles);

    {
      // Define buffers such that:
      // - Buffers are declared in order of filename to internal indexes, _buff0, _buff1, etc.
      //
      // Then:
      // - The PREFIX is defined as everything before the first underscore.
      // - The PRIMARY PREFIX is defined as everything before the first dash, in the prefix.
      // - Map buffPREFIX_NAME to _buffINDEX
      // - Map buffPRIMARY_PREFIX to _buffINDEX
      //
      // e.g.:
      //
      // 0_init.glsl   = _buff_0 = buff0           = buff0_init
      // 1_gen.glsl    = _buff_1 = buff1           = buff1_gen
      // 2_0_post.glsl = _buff_2 =       = buff2_0 = buff2_0_post
      // 2_1_post.glsl = _buff_3 = buff2 = buff2_1 = buff2_1_post
      // 3_out.glsl    = _buff_4 = buff3           = buff3_out

      std::string bufferDecls = "";
      std::map<std::string, std::string> bufferPrefixToInternal;

      for (auto i = 0; i < shaderFiles.size(); i++) {
        auto &file = shaderFiles[i];
        auto baseName = file.stem().string();

        auto prefix = baseName.substr(0, baseName.find('_'));
        auto primaryPrefixIndex = prefix.find('-');
        if (primaryPrefixIndex == std::string::npos) {
          primaryPrefixIndex = prefix.size();
        }
        auto primaryPrefix = prefix.substr(0, primaryPrefixIndex);

        std::replace(baseName.begin(), baseName.end(), '-', '_');
        std::replace(prefix.begin(), prefix.end(), '-', '_');

        auto buffInternal = "_buff" + std::to_string(i);
        auto buffFull = "buff" + baseName;

        bufferDecls += "uniform sampler2D " + buffInternal + ";\n";
        bufferDecls += "#define " + buffFull + " " + buffInternal + "\n";

        std::cout << "BUFFER: " << buffInternal << " -> " << buffFull << std::endl;

        // For primary-only buffers, these end up the same.
        auto buffPrefix = "buff" + prefix;
        auto buffPrimary = "buff" + primaryPrefix;
        bufferPrefixToInternal[buffPrimary] = buffInternal;
        bufferPrefixToInternal[buffPrefix] = buffInternal;
      }

      for (auto &pair : bufferPrefixToInternal) {
        auto buffPrefix = pair.first;
        auto bufferInternal = pair.second;

        bufferDecls += "#define " + buffPrefix + " " + bufferInternal + "\n";
        std::cout << "BUFFER: " << buffPrefix << " -> " << bufferInternal << std::endl;
      }

      addPrelude(preludeSource, preludeLocations, preludeLineCounter, "<buffer decls>",
                 bufferDecls);
    }

    addPreludeFiles(preludeSource, preludeLocations, preludeLineCounter, shaderPreludeFiles);

    std::cout << "PRELUDE LOCATIONS: " << std::endl;

    for (const auto &location : preludeLocations) {
      std::cout << std::setw(4) << location.startingLine << " " << location.name << std::endl;
    }

    try {
      for (const auto &path : shaderFiles) {
        std::cout << "BUILDING SHADER: " << path;

        auto source = gl::getShaderSource(path);
        source = preludeSource + source;

        std::vector<ShaderLocation> shaderLocations(preludeLocations);
        shaderLocations.push_back({path, preludeLineCounter});

        ShaderDataType type = ShaderDataType::UintVec4;
        if (path.stem().string().ends_with("_f")) {
          type = ShaderDataType::Float;
          std::cout << " (FLOAT)" << std::endl;
        } else if (path.stem().string().ends_with("_f4")) {
          type = ShaderDataType::FloatVec4;
          std::cout << " (FLOAT VEC4)" << std::endl;
        } else {
          std::cout << " (UINT VEC4)" << std::endl;
        }

        ShaderErrorParser ShaderErrorParser(shaderLocations);
        auto shader =
            new Shader(path, type, vertexShader, source, shaderFiles.size(), ShaderErrorParser);

        newShaderObjects.push_back(std::unique_ptr<Shader>(shader));
      }
    } catch (...) {
      throw std::runtime_error("Failed to build shaders");
    }

    // Wire up buffers.
    for (auto i = 0; i < newShaderObjects.size(); i++) {
      auto &shader = newShaderObjects[i];
      glUseProgram(shader->program);

      glUniform1i(shader->buffPrevLoc, i == 0 ? 0 : i - 1);
      for (auto j = 0; j < shader->buffLocs.size(); j++) {
        glUniform1i(shader->buffLocs[j], j);
      }
    }

    shaderObjects = std::move(newShaderObjects);
    loadedPaths = std::move(newLoadedPaths);
  }

  int size() { return shaderObjects.size(); }
  std::unique_ptr<Shader> &operator[](int index) { return shaderObjects[index]; }

private:
  static void addPrelude(std::string &preludeSource, std::vector<ShaderLocation> &preludeLocations,
                         int &preludeLineCounter, const std::string &name,
                         const std::string &source) {
    preludeSource += source;

    auto numLines = std::count(source.begin(), source.end(), '\n');
    preludeLocations.push_back({name, preludeLineCounter});
    preludeLineCounter += numLines;
  }

  static void addPreludeFiles(std::string &preludeSource,
                              std::vector<ShaderLocation> &preludeLocations,
                              int &preludeLineCounter,
                              const std::vector<std::filesystem::path> &paths) {
    for (const auto &path : paths) {
      auto source = gl::getShaderSource(path);
      addPrelude(preludeSource, preludeLocations, preludeLineCounter, path, source);
    }
  }
};

class Args {
public:
  std::string shader;
  std::filesystem::path shadersBasePath;
  int fpsLimit;
  bool publishLayers;
  float timeScale;
  int debugBuffer;

  Args(int argc, char *argv[]) {
    argparse::ArgumentParser program("matryx_shadertoy");

    program.add_argument("shader");
    program.add_argument("--shaders-base").default_value(std::filesystem::path("./shaders"));

    program.add_argument("--debug-buffer").default_value(-1).scan<'i', int>();
    program.add_argument("--fps-limit").default_value(120).scan<'i', int>();
    program.add_argument("--publish-layers").default_value(false).implicit_value(true);
    program.add_argument("--time-scale").default_value(1.0f).scan<'f', float>();

    try {
      program.parse_args(argc, argv);
    } catch (const std::runtime_error &err) {
      std::cout << err.what() << std::endl;
      std::cout << program;
      throw;
    }

    shadersBasePath = program.get<std::filesystem::path>("--shaders-base");
    shader = program.get<std::string>("shader");
    if (!std::filesystem::exists(shaderPath())) {
      std::cerr << "Shader does not exist" << std::endl;
      throw;
    }

    debugBuffer = program.get<int>("--debug-buffer");
    fpsLimit = program.get<int>("--fps-limit");
    publishLayers = program.get<bool>("--publish-layers");
    timeScale = program.get<float>("--time-scale");
  }

  std::filesystem::path shaderPath() { return shadersBasePath / shader; }
};

int main(int argc, char *argv[]) {
  Args args(argc, argv);

  gl::setup();
  pixelserver::setup(gl::width, gl::height);

  ShaderManager shaderManager = ShaderManager(args.shadersBasePath, args.shader);
  try {
    shaderManager.load();
  } catch (...) {
    std::cerr << "Failed to load shaders!" << std::endl;
    return 1;
  }

  if (args.debugBuffer != -1 && args.debugBuffer >= shaderManager.shaderObjects.size()) {
    std::cerr << "Invalid debug buffer: " << args.debugBuffer << ", but only "
              << shaderManager.shaderObjects.size() << " buffers exist" << std::endl;
    return 1;
  }

  BufferManager bufferManager = BufferManager();
  for (auto &shader : shaderManager.shaderObjects) {
    bufferManager.add(shader->type);
  }

  int targetBuffer =
      args.debugBuffer == -1 ? shaderManager.shaderObjects.size() - 1 : args.debugBuffer;

  GLuint fb;
  glGenFramebuffers(1, &fb);
  if (glGetError() != GL_NO_ERROR) {
    std::cerr << "Failed to create framebuffer" << std::endl;
    return 1;
  }

  GLuint renderBuffer;
  glGenRenderbuffers(1, &renderBuffer);
  if (glGetError() != GL_NO_ERROR) {
    std::cerr << "Failed to create renderbuffer" << std::endl;
    return 1;
  }

  glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, gl::width, gl::height);
  if (glGetError() != GL_NO_ERROR) {
    std::cerr << "Failed to allocate renderbuffer storage" << std::endl;
    return 1;
  }

  timer::Timer timer = timer::Timer(std::chrono::milliseconds(1000 / args.fpsLimit));
  auto nextCheck = std::chrono::steady_clock::now();
  auto lastShaderModified = std::chrono::file_clock::now();

  uint32_t outPixels[shaderManager.size()][gl::width * gl::height];

  glBindFramebuffer(GL_FRAMEBUFFER, fb);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);

  GLuint attachments[] = {GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1};
  glDrawBuffers(2, attachments);
  glReadBuffer(GL_COLOR_ATTACHMENT0);

  while (true) {
    if (std::chrono::steady_clock::now() > nextCheck) {
      bool needReload = false;
      bool needBufferReload = false;

      auto shaderDirLastModified = std::filesystem::last_write_time(args.shaderPath());
      if (shaderDirLastModified > lastShaderModified) {
        std::cout << "SHADER DIR CHANGED!" << std::endl;
        needReload = true;
        needBufferReload = true;
        lastShaderModified = shaderDirLastModified;
      } else {
        for (auto &path : shaderManager.loadedPaths) {
          auto lastModified = std::filesystem::last_write_time(path);
          if (lastModified > lastShaderModified) {
            std::cout << "SHADER FILE CHANGED: " << path << std::endl;
            needReload = true;
            lastShaderModified = lastModified;
            break;
          }
        }
      }

      if (needReload) {
        try {
          shaderManager.load();

          if (needBufferReload) {
            bufferManager.clear();
            for (auto &shader : shaderManager.shaderObjects) {
              bufferManager.add(shader->type);
            }

            timer.reset();
          }
        } catch (...) {
          std::cerr << "Failed to reload shaders!" << std::endl;
        }
      }

      timer.printFps();
      nextCheck = std::chrono::steady_clock::now() + std::chrono::milliseconds(1000);
    }

    timer::TimerTick tick = timer.get();

    for (auto i = 0; i < shaderManager.size(); i++) {
      auto &shader = shaderManager[i];
      glUseProgram(shader->program);

      glUniform1f(shader->timeLoc, tick.time * args.timeScale);
      glUniform1f(shader->timeDeltaLoc, tick.timeDelta * args.timeScale);
      glUniform1i(shader->frameLoc, tick.index);

      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D,
                             bufferManager.backs[i], 0);

      gl::drawPlane();
      if (args.publishLayers || i == targetBuffer) {
        glReadPixels(0, 0, gl::width, gl::height, GL_RGBA, GL_UNSIGNED_BYTE, outPixels[i]);
      }
    }

    for (auto i = 0; i < shaderManager.size(); i++) {
      bufferManager.swap(i);
      glActiveTexture(GL_TEXTURE0 + i);
      glBindTexture(GL_TEXTURE_2D, bufferManager.fronts[i]);
    }

    pixelserver::send(outPixels[targetBuffer]);
    if (args.publishLayers) {
      pixelserver::sendLayers(outPixels[0], shaderManager.size());
    }

    timer.delayUntilNextFrame(tick);
  }

  return 0;
}

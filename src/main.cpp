#include <algorithm>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <iomanip>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include <glad/egl.h>
#include <glad/gles2.h>

#include <argparse/argparse.hpp>
#include <plog/Appenders/ColorConsoleAppender.h>
#include <plog/Formatters/FuncMessageFormatter.h>
#include <plog/Init.h>
#include <plog/Log.h>
#include <zmq.hpp>

#include "gl.hpp"
#include "pixelserver.hpp"
#include "timer.hpp"

struct ShaderLocation {
  std::string name;
  int id;
};

class ShaderLocations {
private:
  std::vector<ShaderLocation> locations;

public:
  ShaderLocations() : locations() {}
  ShaderLocations(ShaderLocations &other) : locations(other.locations) {}

  int add(std::string name) {
    locations.push_back({name, static_cast<int>(locations.size())});
    return locations.size() - 1;
  }

  std::size_t size() { return locations.size(); }

  ShaderLocation operator[](int index) { return locations[index]; }
  ShaderLocations &operator=(const ShaderLocations &other) {
    if (this != &other) {
      locations = other.locations;
    }
    return *this;
  }

  std::vector<ShaderLocation>::iterator begin() { return locations.begin(); }
  std::vector<ShaderLocation>::iterator end() { return locations.end(); }
};

class ShaderErrorParser {
private:
  ShaderLocations shaderLocations;

public:
  ShaderErrorParser() : shaderLocations() {}
  ShaderErrorParser(ShaderLocations shaderLocations) : shaderLocations(shaderLocations) {}

  void parse(const std::string_view error) {
    if (shaderLocations.size() == 0) {
      PLOG_ERROR << error;
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

      auto idNumber = std::stoi(std::string(line.substr(0, colonPos)));
      auto lineNumber = std::stoi(std::string(line.substr(colonPos + 1)));

      auto shaderLocation = shaderLocations[idNumber];
      auto shaderName = shaderLocation.name;
      auto shaderLine = lineNumber;

      std::string errorOut = shaderName + ":" + std::to_string(shaderLine) + ":" +
                             std::string(line.substr(messagePos + 1));

      PLOG_ERROR << errorOut;
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
      PLOG_FATAL << "Failed to create shader program";
      throw;
    }

    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    if (fragmentShader == 0) {
      PLOG_FATAL << "Failed to create fragment shader";
      throw;
    }

    const char *fragmentShaders[] = {fragmentShaderSource.data()};
    glShaderSource(fragmentShader, 1, fragmentShaders, NULL);
    glCompileShader(fragmentShader);

    GLint shaderCompiled;
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &shaderCompiled);
    if (shaderCompiled == GL_FALSE) {
      PLOG_ERROR << "Failed to compile fragment shader";

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
      PLOG_ERROR << "Failed to link program";
      GLint logLength;
      glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);

      if (logLength > 0) {
        char *log = new char[logLength];
        glGetProgramInfoLog(program, logLength, &logLength, log);
        PLOG_ERROR << log;

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
  GLint buffThisLoc;
  GLint frameLoc;
  GLint resolutionLoc;

  Shader(std::filesystem::path path, ShaderDataType type, GLuint vertexShader,
         std::string_view fragmentShaderSource, int bufferCount, ShaderErrorParser &errorParser)
      : BaseShader(vertexShader, fragmentShaderSource, errorParser), path(path), type(type) {
    timeLoc = glGetUniformLocation(program, "time");
    timeDeltaLoc = glGetUniformLocation(program, "timeDelta");
    frameLoc = glGetUniformLocation(program, "frame");
    buffPrevLoc = glGetUniformLocation(program, "buffPrev");
    buffThisLoc = glGetUniformLocation(program, "buffThis");
    resolutionLoc = glGetUniformLocation(program, "resolution");

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
        PLOG_FATAL << "Failed to create framebuffer texture";
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
    std::string preludeSource;
    ShaderLocations preludeLocations;

    std::vector<std::unique_ptr<Shader>> newShaderObjects;
    std::vector<std::filesystem::path> newLoadedPaths;

    std::filesystem::path preludeDirPath = shadersBaseDirPath / "prelude";
    std::filesystem::path shaderDirPath = shadersBaseDirPath / shaderName;

    PLOG_INFO << "Shaders base dir: " << shadersBaseDirPath;
    PLOG_INFO << "Prelude dir: " << preludeDirPath;
    PLOG_INFO << "Shader dir: " << shaderDirPath;

    auto vertexShader = gl::getVertexShader(shadersBaseDirPath / "vertex.glsl");

    std::vector<std::filesystem::path> preludeFiles;
    std::vector<std::filesystem::path> shaderFiles;
    std::vector<std::filesystem::path> shaderPreludeFiles;

    for (const auto &entry : std::filesystem::directory_iterator(preludeDirPath)) {
      auto path = entry.path();

      if (path.extension() != ".glsl") {
        continue;
      }

      PLOG_INFO << "PRELUDE: Found " << path;
      preludeFiles.push_back(path);
    }

    for (const auto &entry : std::filesystem::directory_iterator(shaderDirPath)) {
      auto path = entry.path();

      if (path.extension() != ".glsl") {
        continue;
      }

      if (path.filename().string().starts_with("prelude")) {
        PLOG_INFO << "SHADER PRELUDE: Found" << path;
        shaderPreludeFiles.push_back(path);
      } else {
        PLOG_INFO << "SHADER: Found " << path;
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

    addPreludeFiles(preludeSource, preludeLocations, preludeFiles);

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

      for (std::size_t i = 0; i < shaderFiles.size(); i++) {
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

        PLOG_DEBUG << "BUFFER: " << buffInternal << " -> " << buffFull;

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
        PLOG_DEBUG << "BUFFER: " << buffPrefix << " -> " << bufferInternal;
      }

      addPrelude(preludeSource, preludeLocations, "<buffer decls>", bufferDecls);
    }

    addPreludeFiles(preludeSource, preludeLocations, shaderPreludeFiles);

    PLOG_DEBUG << "PRELUDE IDS: ";
    for (const auto &location : preludeLocations) {
      PLOG_DEBUG << std::setw(4) << location.id << " " << location.name;
    }

    try {
      for (const auto &path : shaderFiles) {

        ShaderLocations shaderLocations = preludeLocations;
        int id = shaderLocations.add(path);
        auto source = preludeSource + getLocationLine(id) + gl::getShaderSource(path);

        ShaderDataType type = ShaderDataType::UintVec4;
        if (path.stem().string().ends_with("_f")) {
          type = ShaderDataType::Float;
          PLOG_DEBUG << "BUILDING SHADER: " << path << " (FLOAT)";
        } else if (path.stem().string().ends_with("_f4")) {
          type = ShaderDataType::FloatVec4;
          PLOG_DEBUG << "BUILDING SHADER: " << path << " (FLOAT VEC4)";
        } else {
          PLOG_DEBUG << "BUILDING SHADER: " << path << " (UINT VEC4)";
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
    for (std::size_t i = 0; i < newShaderObjects.size(); i++) {
      auto &shader = newShaderObjects[i];
      glUseProgram(shader->program);

      glUniform1i(shader->buffPrevLoc, i == 0 ? 0 : i - 1);
      glUniform1i(shader->buffThisLoc, i);

      for (std::size_t j = 0; j < shader->buffLocs.size(); j++) {
        glUniform1i(shader->buffLocs[j], j);
      }

      glUniform2f(shader->resolutionLoc, gl::width, gl::height);
    }

    shaderObjects = std::move(newShaderObjects);
    loadedPaths = std::move(newLoadedPaths);
  }

  int size() { return shaderObjects.size(); }
  std::unique_ptr<Shader> &operator[](int index) { return shaderObjects[index]; }

private:
  static void addPrelude(std::string &preludeSource, ShaderLocations &preludeLocations,
                         const std::string &name, const std::string &source) {

    int preludeId = preludeLocations.add(name);
    preludeSource += getLocationLine(preludeId);
    preludeSource += source;
  }

  static void addPreludeFiles(std::string &preludeSource, ShaderLocations &preludeLocations,
                              const std::vector<std::filesystem::path> &paths) {
    for (const auto &path : paths) {
      auto source = gl::getShaderSource(path);
      addPrelude(preludeSource, preludeLocations, path, source);
    }
  }

  static std::string getLocationLine(int id) {
    if (id == 0) {
      return "";
    }

    return "#line 1 " + std::to_string(id) + "\n";
  }
};

class Args {
public:
  std::string shader;
  std::filesystem::path shadersBasePath;
  int fpsLimit;
  float timeScale;
  int debugBuffer;
  int width;
  int height;

  std::string matryxEndpoint;
  std::string layersEndpoint;
  std::string outputEndpoint;
  bool publishLayers;

  Args(int argc, char *argv[]) {
    argparse::ArgumentParser program("matryx_shadertoy");

    program.add_argument("shader");
    program.add_argument("--shaders-base").default_value(std::filesystem::path("./shaders"));

    program.add_argument("--width").default_value(192).scan<'i', int>();
    program.add_argument("--height").default_value(320).scan<'i', int>();

    program.add_argument("--debug-buffer").default_value(-1).scan<'i', int>();
    program.add_argument("--fps-limit").default_value(120).scan<'i', int>();
    program.add_argument("--publish-layers").default_value(false).implicit_value(true);
    program.add_argument("--time-scale").default_value(1.0f).scan<'f', float>();

    program.add_argument("--matryx-endpoint")
        .default_value(std::string("ipc:///tmp/matrix-frames.sock"));
    program.add_argument("--layers-endpoint")
        .default_value(std::string("ipc:///tmp/matryx-shadertoy-layers.sock"));
    program.add_argument("--output-endpoint")
        .default_value(std::string("ipc:///tmp/matryx-shadertoy-output.sock"));

    try {
      program.parse_args(argc, argv);
    } catch (const std::runtime_error &err) {
      PLOG_FATAL << err.what();
      PLOG_INFO << program;
      throw;
    }

    shadersBasePath = program.get<std::filesystem::path>("--shaders-base");
    shader = program.get<std::string>("shader");
    if (!std::filesystem::exists(shaderPath())) {
      PLOG_ERROR << "Shader does not exist";
      throw;
    }

    width = program.get<int>("--width");
    height = program.get<int>("--height");

    debugBuffer = program.get<int>("--debug-buffer");
    fpsLimit = program.get<int>("--fps-limit");
    publishLayers = program.get<bool>("--publish-layers");
    timeScale = program.get<float>("--time-scale");

    matryxEndpoint = program.get<std::string>("--matryx-endpoint");
    layersEndpoint = program.get<std::string>("--layers-endpoint");
    outputEndpoint = program.get<std::string>("--output-endpoint");
  }

  void print() {
    PLOG_DEBUG << "shader: " << shader;
    PLOG_DEBUG << "shadersBasePath: " << shadersBasePath;
    PLOG_DEBUG << "fpsLimit: " << fpsLimit;
    PLOG_DEBUG << "timeScale: " << timeScale;
    PLOG_DEBUG << "debugBuffer: " << debugBuffer;
    PLOG_DEBUG << "width: " << width;
    PLOG_DEBUG << "height: " << height;
    PLOG_DEBUG << "matryxEndpoint: " << matryxEndpoint;
    PLOG_DEBUG << "layersEndpoint: " << layersEndpoint;
    PLOG_DEBUG << "outputEndpoint: " << outputEndpoint;
    PLOG_DEBUG << "publishLayers: " << publishLayers;
  }

  std::filesystem::path shaderPath() { return shadersBasePath / shader; }
};

int main(int argc, char *argv[]) {
  static plog::ColorConsoleAppender<plog::FuncMessageFormatter> consoleAppender;
  plog::init(plog::debug, &consoleAppender);

  Args args(argc, argv);
  args.print();

  gl::setup(args.width, args.height);
  pixelserver::setup(gl::width, gl::height, args.matryxEndpoint, args.layersEndpoint,
                     args.outputEndpoint);

  ShaderManager shaderManager = ShaderManager(args.shadersBasePath, args.shader);
  try {
    shaderManager.load();
  } catch (...) {
    PLOG_FATAL << "Failed to load shaders!";
    return 1;
  }

  if (args.debugBuffer != -1 &&
      args.debugBuffer >= static_cast<int>(shaderManager.shaderObjects.size())) {
    PLOG_FATAL << "Invalid debug buffer: " << args.debugBuffer << ", but only "
               << shaderManager.shaderObjects.size() << " buffers exist";
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
    PLOG_FATAL << "Failed to create framebuffer";
    return 1;
  }

  GLuint renderBuffer;
  glGenRenderbuffers(1, &renderBuffer);
  if (glGetError() != GL_NO_ERROR) {
    PLOG_FATAL << "Failed to create renderbuffer";
    return 1;
  }

  glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, gl::width, gl::height);
  if (glGetError() != GL_NO_ERROR) {
    PLOG_FATAL << "Failed to allocate renderbuffer storage";
    return 1;
  }

  timer::Timer timer = timer::Timer(std::chrono::milliseconds(1000 / args.fpsLimit));
  auto nextCheck = std::chrono::steady_clock::now();
  auto lastShaderModified = std::chrono::file_clock::now();

  std::vector<std::vector<uint32_t>> outPixels(shaderManager.size());
  for (auto i = 0; i < shaderManager.size(); i++) {
    outPixels[i].resize(gl::width * gl::height);
  }

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
        PLOG_INFO << "SHADER DIR CHANGED!";
        needReload = true;
        needBufferReload = true;
        lastShaderModified = shaderDirLastModified;
      } else {
        for (auto &path : shaderManager.loadedPaths) {
          auto lastModified = std::filesystem::last_write_time(path);
          if (lastModified > lastShaderModified) {
            PLOG_INFO << "SHADER FILE CHANGED: " << path;
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
          PLOG_ERROR << "Failed to reload shaders!";
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
        glReadPixels(0, 0, gl::width, gl::height, GL_RGBA, GL_UNSIGNED_BYTE, outPixels[i].data());
      }
    }

    for (auto i = 0; i < shaderManager.size(); i++) {
      bufferManager.swap(i);
      glActiveTexture(GL_TEXTURE0 + i);
      glBindTexture(GL_TEXTURE_2D, bufferManager.fronts[i]);
    }

    pixelserver::send(outPixels[targetBuffer].data());
    if (args.publishLayers) {
      pixelserver::sendLayers(outPixels[0].data(), shaderManager.size());
    }

    timer.delayUntilNextFrame(tick);
  }

  return 0;
}

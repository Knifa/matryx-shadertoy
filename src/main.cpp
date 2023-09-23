#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <regex>
#include <string>
#include <thread>
#include <vector>

#include <glad/egl.h>
#include <glad/gles2.h>

#include <argparse/argparse.hpp>
#include <zmq.hpp>

#include "gl.hpp"
#include "pixelserver.hpp"
#include "timer.hpp"

struct ShaderLocation
{
  std::string name;
  int startingLine;
};

class ShaderErrorParser
{
private:
  std::vector<ShaderLocation> shaderLocations;

public:
  ShaderErrorParser() : shaderLocations() {}

  ShaderErrorParser(std::vector<ShaderLocation> shaderLocations) : shaderLocations(shaderLocations)
  {
  }

  void parse(std::string error)
  {
    if (shaderLocations.size() == 0)
    {
      std::cerr << error << std::endl;
      return;
    }

    std::vector<std::string> lines;
    std::string line;
    std::istringstream stream(error);
    while (std::getline(stream, line))
    {
      lines.push_back(line);
    }

    for (auto &line : lines)
    {
      auto colonPos = line.find(':');
      if (colonPos == std::string::npos)
      {
        continue;
      }

      auto messagePos = line.find(':', colonPos + 1);
      if (messagePos == std::string::npos)
      {
        continue;
      }

      auto lineNumber = std::stoi(line.substr(colonPos + 1)) - 1;
      auto shaderLocation = std::find_if(shaderLocations.rbegin(), shaderLocations.rend(),
                                         [lineNumber](ShaderLocation &shaderLocation)
                                         { return shaderLocation.startingLine <= lineNumber; });

      auto shaderName = shaderLocation->name;
      auto shaderLine = lineNumber - shaderLocation->startingLine + 1;

      line = shaderName + ":" + std::to_string(shaderLine) + ":" + line.substr(messagePos + 1);

      std::cerr << line << std::endl;
    }
  }
};

enum class ShaderDataType
{
  UintVec4,
  Float,
  FloatVec4,
};

class BaseShader
{
public:
  GLuint program;
  GLuint fragmentShader;

  BaseShader(ShaderDataType type, GLuint vertexShader, std::string fragmentShaderSource,
             ShaderErrorParser &errorParser)
  {
    program = glCreateProgram();

    if (program == 0)
    {
      std::cerr << "Failed to create shader program" << std::endl;
      throw;
    }

    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    if (fragmentShader == 0)
    {
      std::cerr << "Failed to create fragment shader" << std::endl;
      throw;
    }

    const char *fragmentShaders[] = {fragmentShaderSource.c_str()};
    glShaderSource(fragmentShader, 1, fragmentShaders, NULL);
    glCompileShader(fragmentShader);

    GLint shaderCompiled;
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &shaderCompiled);
    if (shaderCompiled == GL_FALSE)
    {
      std::cerr << "Failed to compile fragment shader" << std::endl;

      GLint logLength;
      glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, &logLength);

      char *log = new char[logLength];
      glGetShaderInfoLog(fragmentShader, logLength, &logLength, log);
      errorParser.parse(log);

      delete[] log;
      throw;
    }

    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);

    glBindAttribLocation(program, 0, "a_position");

    glLinkProgram(program);

    GLint programLinked;
    glGetProgramiv(program, GL_LINK_STATUS, &programLinked);
    if (programLinked == GL_FALSE)
    {
      std::cerr << "Failed to link program" << std::endl;
      GLint logLength;
      glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);

      if (logLength > 0)
      {
        char *log = new char[logLength];
        glGetProgramInfoLog(program, logLength, &logLength, log);
        std::cerr << log << std::endl;

        delete[] log;
      }

      throw;
    }
  }
};

class Shader : public BaseShader
{
public:
  GLuint fbTextureFront;
  GLuint fbTextureBack;

  GLint timeLoc;
  GLint timeDeltaLoc;
  std::vector<GLint> buffLocs;
  GLint buffPrevLoc;
  GLint frameLoc;

  Shader(ShaderDataType type, GLuint vertexShader, std::string fragmentShaderSource,
         int bufferCount, ShaderErrorParser &errorParser)
      : BaseShader(type, vertexShader, fragmentShaderSource, errorParser)
  {
    timeLoc = glGetUniformLocation(program, "time");
    timeDeltaLoc = glGetUniformLocation(program, "timeDelta");
    frameLoc = glGetUniformLocation(program, "frame");
    buffPrevLoc = glGetUniformLocation(program, "buffPrev");

    buffLocs.resize(bufferCount);
    for (auto i = 0; i < bufferCount; i++)
    {
      buffLocs[i] = glGetUniformLocation(program, ("_buff" + std::to_string(i)).c_str());
    }

    fbTextureFront = 0;
    fbTextureBack = 0;

    GLint glInternalFormat;
    GLenum glFormat;
    GLenum glType;
    switch (type)
    {
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

    for (auto fbTexture : {&fbTextureFront, &fbTextureBack})
    {
      glGenTextures(1, fbTexture);
      glBindTexture(GL_TEXTURE_2D, *fbTexture);
      glTexImage2D(GL_TEXTURE_2D, 0, glInternalFormat, gl::width, gl::height, 0, glFormat, glType,
                   NULL);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

      if (glGetError() != GL_NO_ERROR)
      {
        std::cerr << "Failed to create framebuffer texture" << std::endl;
        throw;
      }
    }
  }

  void swap()
  {
    GLuint temp = fbTextureFront;
    fbTextureFront = fbTextureBack;
    fbTextureBack = temp;
  }
};

class Args
{
public:
  std::string shader;
  std::filesystem::path shadersBasePath;
  int fpsLimit;

  Args(int argc, char *argv[])
  {
    argparse::ArgumentParser program("matryx_shadertoy");
    program.add_argument("shader");
    program.add_argument("--shaders-base").default_value(std::filesystem::path("./shaders"));
    program.add_argument("--fps-limit").default_value(120).scan<'i', int>();

    try
    {
      program.parse_args(argc, argv);
    }
    catch (const std::runtime_error &err)
    {
      std::cout << err.what() << std::endl;
      std::cout << program;
      throw;
    }

    shadersBasePath = program.get<std::filesystem::path>("--shaders-base");
    shader = program.get<std::string>("shader");

    if (!std::filesystem::exists(shaderPath()))
    {
      std::cerr << "Shader does not exist" << std::endl;
      throw;
    }

    fpsLimit = program.get<int>("--fps-limit");
  }

  std::filesystem::path shaderPath() { return shadersBasePath / shader; }
};

class ShaderManager
{
private:
  int preludeLineCounter = 0;
  std::string preludeSource;
  std::vector<ShaderLocation> preludeLocations;

public:
  std::vector<Shader *> shaderObjects;

  ShaderManager(std::filesystem::path shadersBaseDirPath, std::string shaderName)
  {
    std::filesystem::path preludeDirPath = shadersBaseDirPath / "prelude";
    std::filesystem::path shaderDirPath = shadersBaseDirPath / shaderName;

    std::cout << "Shaders base dir: " << shadersBaseDirPath << std::endl;
    std::cout << "Prelude dir: " << preludeDirPath << std::endl;
    std::cout << "Shader dir: " << shaderDirPath << std::endl;

    auto vertexShader = gl::getVertexShader(shadersBaseDirPath / "vertex.glsl");

    std::vector<std::filesystem::path> preludeFiles;
    std::vector<std::filesystem::path> shaderFiles;
    std::vector<std::filesystem::path> shaderPreludeFiles;

    for (const auto &entry : std::filesystem::directory_iterator(preludeDirPath))
    {
      auto path = entry.path();

      if (path.extension() != ".glsl")
      {
        continue;
      }

      std::cout << "PRELUDE: Found " << path << std::endl;
      preludeFiles.push_back(path);
    }

    for (const auto &entry : std::filesystem::directory_iterator(shaderDirPath))
    {
      auto path = entry.path();

      if (path.extension() != ".glsl")
      {
        continue;
      }

      if (path.filename().string().starts_with("prelude"))
      {
        std::cout << "SHADER PRELUDE: Found" << path << std::endl;
        shaderPreludeFiles.push_back(path);
      }
      else
      {
        std::cout << "SHADER: Found " << path << std::endl;
        shaderFiles.push_back(path);
      }
    }

    std::sort(preludeFiles.begin(), preludeFiles.end());
    std::sort(shaderPreludeFiles.begin(), shaderPreludeFiles.end());
    std::sort(shaderFiles.begin(), shaderFiles.end());

    addPreludeFiles(preludeFiles);

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

      for (auto i = 0; i < shaderFiles.size(); i++)
      {
        auto &file = shaderFiles[i];
        auto baseName = file.stem().string();

        auto prefix = baseName.substr(0, baseName.find('_'));
        auto primaryPrefixIndex = prefix.find('-');
        if (primaryPrefixIndex == std::string::npos)
        {
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

      for (auto &pair : bufferPrefixToInternal)
      {
        auto buffPrefix = pair.first;
        auto bufferInternal = pair.second;

        bufferDecls += "#define " + buffPrefix + " " + bufferInternal + "\n";
        std::cout << "BUFFER: " << buffPrefix << " -> " << bufferInternal << std::endl;
      }

      addPrelude("<buffer decls>", bufferDecls);
    }

    addPreludeFiles(shaderPreludeFiles);

    std::cout << "PRELUDE LOCATIONS: " << std::endl;

    for (const auto &location : preludeLocations)
    {
      std::cout << std::setw(4) << location.startingLine << " " << location.name << std::endl;
    }

    for (const auto &path : shaderFiles)
    {
      std::cout << "BUILDING SHADER: " << path << std::endl;

      auto source = gl::getShaderSource(path);
      source = preludeSource + source;

      std::vector<ShaderLocation> shaderLocations(preludeLocations);
      shaderLocations.push_back({path, preludeLineCounter});

      ShaderDataType type = ShaderDataType::UintVec4;
      if (path.stem().string().ends_with("_f"))
      {
        type = ShaderDataType::Float;
      }
      else if (path.stem().string().ends_with("_f4"))
      {
        type = ShaderDataType::FloatVec4;
      }

      ShaderErrorParser ShaderErrorParser(shaderLocations);
      Shader *shader =
          new Shader(type, vertexShader, source, shaderFiles.size(), ShaderErrorParser);

      shaderObjects.push_back(shader);
    }

    for (auto i = 0; i < shaderObjects.size(); i++)
    {
      auto &shader = shaderObjects[i];
      glUseProgram(shader->program);

      glUniform1i(shader->buffPrevLoc, i == 0 ? 0 : i - 1);
      for (auto j = 0; j < shader->buffLocs.size(); j++)
      {
        glUniform1i(shader->buffLocs[j], j);
      }
    }
  }

  int size() { return shaderObjects.size(); }

  Shader *operator[](int index) { return shaderObjects[index]; }

private:
  void addPrelude(const std::string &name, const std::string &source)
  {
    preludeSource += source;

    auto numLines = std::count(source.begin(), source.end(), '\n');
    preludeLocations.push_back({name, preludeLineCounter});
    preludeLineCounter += numLines;
  }

  void addPreludeFiles(const std::vector<std::filesystem::path> &paths)
  {
    for (const auto &path : paths)
    {
      auto source = gl::getShaderSource(path);
      addPrelude(path, source);
    }
  }
};

int main(int argc, char *argv[])
{
  Args args(argc, argv);

  gl::setup();
  pixelserver::setup(gl::width, gl::height);

  ShaderManager shaderManager(args.shadersBasePath, args.shader);

  GLuint fb;
  glGenFramebuffers(1, &fb);
  if (glGetError() != GL_NO_ERROR)
  {
    std::cerr << "Failed to create framebuffer" << std::endl;
    return 1;
  }

  GLuint renderBuffer;
  glGenRenderbuffers(1, &renderBuffer);
  if (glGetError() != GL_NO_ERROR)
  {
    std::cerr << "Failed to create renderbuffer" << std::endl;
    return 1;
  }

  glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
  glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, gl::width, gl::height);
  if (glGetError() != GL_NO_ERROR)
  {
    std::cerr << "Failed to allocate renderbuffer storage" << std::endl;
    return 1;
  }

  timer::Timer timer(std::chrono::milliseconds(1000 / args.fpsLimit));
  int frameCount = 0;
  auto nextFpsPrint = std::chrono::steady_clock::now();

  uint32_t outPixels[shaderManager.size()][gl::width * gl::height];

  glBindFramebuffer(GL_FRAMEBUFFER, fb);
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);

  GLuint attachments[] = {GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1};
  glDrawBuffers(2, attachments);
  glReadBuffer(GL_COLOR_ATTACHMENT0);

  while (true)
  {
    timer::TimerTick tick = timer.get();

    if (std::chrono::steady_clock::now() > nextFpsPrint)
    {
      timer.printFps();
      nextFpsPrint = std::chrono::steady_clock::now() + std::chrono::milliseconds(1000);
    }

    for (auto i = 0; i < shaderManager.size(); i++)
    {
      auto shader = shaderManager[i];
      glUseProgram(shader->program);

      glUniform1f(shader->timeLoc, tick.time);
      glUniform1f(shader->timeDeltaLoc, tick.timeDelta);
      glUniform1i(shader->frameLoc, frameCount);

      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D,
                             shader->fbTextureBack, 0);

      gl::drawPlane();
      glReadPixels(0, 0, gl::width, gl::height, GL_RGBA, GL_UNSIGNED_BYTE, outPixels[i]);
    }

    for (auto i = 0; i < shaderManager.size(); i++)
    {
      auto shader = shaderManager[i];
      shader->swap();
      glActiveTexture(GL_TEXTURE0 + i);
      glBindTexture(GL_TEXTURE_2D, shader->fbTextureFront);
    }

    pixelserver::send(outPixels[shaderManager.size() - 1]);
    timer.delayUntilNextFrame(tick);
    frameCount++;
  }

  return 0;
}

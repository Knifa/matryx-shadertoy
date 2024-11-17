cmake_minimum_required(VERSION 3.18)

project(matryx_shadertoy)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -mtune=native -Wall -Wextra")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(ZMQ REQUIRED libzmq)

# fetch latest argparse
include(FetchContent)
FetchContent_Declare(
  argparse
  GIT_REPOSITORY https://github.com/p-ranav/argparse.git
  GIT_TAG v2.9
)
FetchContent_MakeAvailable(argparse)

add_executable(matryx_shadertoy
  ./src/main.cpp
  ./src/pixelserver.cpp
  ./src/gl.cpp
  ./src/timer.cpp
)
target_link_libraries(matryx_shadertoy PRIVATE argparse zmq)
target_compile_features(matryx_shadertoy PRIVATE cxx_std_20)
target_compile_options(matryx_shadertoy PRIVATE
  -O3
  -mtune=native
  -Wall
)

# https://gen.glad.sh/#generator=c&api=egl%3D1.4%2Cgles2%3D3.2&profile=gl%3Dcompatibility%2Cgles1%3Dcommon&extensions=EGL_EXT_device_base%2CEGL_EXT_device_drm%2CEGL_EXT_device_drm_render_node%2CEGL_EXT_device_query%2CEGL_EXT_device_query_name%2CEGL_EXT_platform_base%2CEGL_EXT_platform_device%2CEGL_EXT_platform_wayland%2CEGL_KHR_platform_gbm&options=LOADER%2CMERGE
target_include_directories(matryx_shadertoy PRIVATE glad/include)
target_sources(matryx_shadertoy PRIVATE
  glad/src/egl.c
  glad/src/gles2.c
)
target_link_libraries(matryx_shadertoy PRIVATE dl)

# add_executable(matryx_fb ./src/fb.cpp)
# target_link_libraries(matryx_fb PRIVATE zmq)
# target_compile_options(matryx_fb PRIVATE
#   -O3
#   -march=native
#   -Wall
# )

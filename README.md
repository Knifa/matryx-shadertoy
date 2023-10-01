# Matryx Shadertoy

A client for the [led-matrix-zmq-server](https://github.com/Knifa/led-matrix-zmq-server) to generate procedural patterns with shaders using OpenGL.

## Prerequisites

- [libzmq](https://zeromq.org/) - A high performance asynchronous socket based messaging library, available from a variety of package managers
- [cppzmq](https://github.com/zeromq/cppzmq) - A C++ wrapper for ZeroMQ

## Building

The project can be built with cmake, for example with the following
```
cmake -B build
cmake --build build -j8
```

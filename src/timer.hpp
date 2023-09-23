#pragma once

#include <chrono>
#include <iostream>
#include <thread>

namespace timer
{
class TimerTick
{
public:
  std::chrono::steady_clock::time_point start;
  std::chrono::steady_clock::time_point last;
  std::chrono::steady_clock::time_point now;

  float time;
  float timeDelta;

  TimerTick(std::chrono::steady_clock::time_point start, std::chrono::steady_clock::time_point last,
            std::chrono::steady_clock::time_point now);
};

class Timer
{
private:
  std::chrono::steady_clock::time_point start;
  std::chrono::steady_clock::time_point last;

  std::chrono::milliseconds targetFrameTime;

  float avgTimeDelta;

public:
  Timer(std::chrono::milliseconds targetFrameTime);

  TimerTick get();
  void delayUntilNextFrame(TimerTick &tick);
  void printFps();
};
}; // namespace timer

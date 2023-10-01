#pragma once

#include <chrono>
#include <iostream>
#include <thread>

namespace timer {
class TimerTick {
public:
  std::chrono::steady_clock::time_point start;
  std::chrono::steady_clock::time_point last;
  std::chrono::steady_clock::time_point now;

  float time;
  float timeDelta;
  int index;

  TimerTick(std::chrono::steady_clock::time_point start, std::chrono::steady_clock::time_point last,
            std::chrono::steady_clock::time_point now, int index);
};

class Timer {
private:
  std::chrono::steady_clock::time_point start;
  std::chrono::steady_clock::time_point last;
  int count;

  std::chrono::milliseconds targetFrameTime;

  float avgTimeDelta;

public:
  Timer(std::chrono::milliseconds targetFrameTime);

  TimerTick get();
  void reset();

  void delayUntilNextFrame(TimerTick &tick);
  void printFps();
};
}; // namespace timer

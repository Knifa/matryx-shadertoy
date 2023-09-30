#include "timer.hpp"

#include <iomanip>

timer::TimerTick::TimerTick(std::chrono::steady_clock::time_point start,
                            std::chrono::steady_clock::time_point last,
                            std::chrono::steady_clock::time_point now)
    : start(start), last(last), now(now) {
  time = std::chrono::duration_cast<std::chrono::nanoseconds>(now - start).count() / 1000000000.0f;
  timeDelta =
      std::chrono::duration_cast<std::chrono::nanoseconds>(now - last).count() / 1000000000.0f;
}

timer::Timer::Timer(std::chrono::milliseconds targetFrameTime)
    : targetFrameTime(targetFrameTime), avgTimeDelta(0.0f) {
  start = std::chrono::steady_clock::now();
  last = start;
}

timer::TimerTick timer::Timer::get() {
  auto now = std::chrono::steady_clock::now();

  // Roll over if we've been running for a long time.
  if (now - start > std::chrono::hours(24)) {
    start = now;
  }

  TimerTick tick(start, last, now);
  last = now;

  {
    // Update average time delta for FPS count.
    float mix = std::min(1.0f, tick.timeDelta / 1.0f);
    avgTimeDelta = avgTimeDelta * (1.0f - mix) + tick.timeDelta * mix;
  }

  return tick;
}

void timer::Timer::delayUntilNextFrame(TimerTick &tick) {
  auto now = std::chrono::steady_clock::now();

  auto thisFrameTime = std::chrono::duration_cast<std::chrono::nanoseconds>(now - tick.now);
  auto sleepTime = targetFrameTime - thisFrameTime;

  if (sleepTime > std::chrono::nanoseconds(0)) {
    std::this_thread::sleep_for(sleepTime);
  }
}

void timer::Timer::printFps() {
  std::cout << "\033[2K\r" << std::fixed << std::setprecision(2) << 1.0f / avgTimeDelta << " Hz"
            << std::flush;
}

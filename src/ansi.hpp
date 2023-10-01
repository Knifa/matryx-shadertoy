#pragma once

#include <string>

namespace ansi {
const std::string ESC = "\033[";
const std::string CLEAR_LINE = ESC + "2K\r";
} // namespace ansi

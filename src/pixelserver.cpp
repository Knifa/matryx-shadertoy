#include "pixelserver.hpp"
#include <span>
#include <zmq.hpp>

static constexpr auto BPP = 4;
static constexpr auto ZMQ_ENDPOINT = "ipc:///var/run/matryx";

static zmq::context_t z_context;
static zmq::socket_t z_socket(z_context, ZMQ_REQ);

static int width;
static int height;

namespace pixelserver
{
void setup(const int width, const int height)
{
  ::width = width;
  ::height = height;

  z_socket.connect(ZMQ_ENDPOINT);
}

void send(uint32_t *pixels)
{
  zmq::const_buffer buffer(pixels, width * height * BPP);
  z_socket.send(buffer);

  zmq::message_t reply;
  static_cast<void>(z_socket.recv(reply));
}
} // namespace pixelserver

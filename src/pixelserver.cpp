#include "pixelserver.hpp"

#include <span>
#include <zmq.hpp>
#include <zmq_addon.hpp>

static constexpr auto BPP = 4;
static constexpr auto ZMQ_PIX_ENDPOINT = "ipc:///var/run/matryx";
static constexpr auto ZMQ_LAYERS_ENDPOINT = "ipc:///var/run/matryx-layers";

static zmq::context_t z_context;
static zmq::socket_t z_pix_socket(z_context, ZMQ_REQ);
static zmq::socket_t z_layers_socket(z_context, ZMQ_PUB);

static int width;
static int height;

namespace pixelserver
{
void setup(const int width, const int height)
{
  ::width = width;
  ::height = height;

  z_pix_socket.connect(ZMQ_PIX_ENDPOINT);
  z_layers_socket.bind(ZMQ_LAYERS_ENDPOINT);
}

void send(uint32_t *pixels)
{
  zmq::const_buffer buffer(pixels, width * height * BPP);
  z_pix_socket.send(buffer);

  zmq::message_t reply;
  static_cast<void>(z_pix_socket.recv(reply));
}

void sendLayers(uint32_t *pixels, const int count)
{
  zmq::multipart_t message;
  message.addstr("layers");
  message.addmem(&count, sizeof(count));
  message.addmem(pixels, width * height * BPP * count);

  message.send(z_layers_socket);
}
} // namespace pixelserver

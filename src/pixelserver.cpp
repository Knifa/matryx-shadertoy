#include "pixelserver.hpp"

#include <span>
#include <zmq.hpp>
#include <zmq_addon.hpp>

static constexpr auto BPP = 4;

static zmq::context_t z_context;

static zmq::socket_t z_matryx_socket(z_context, ZMQ_REQ);
static zmq::socket_t z_layers_socket(z_context, ZMQ_PUB);
static zmq::socket_t z_output_socket(z_context, ZMQ_PUB);

static int width;
static int height;

namespace pixelserver {
void setup(const int width, const int height, const std::string &matryxEndpoint,
           const std::string &layersEndpoint, const std::string &outputEndpoint) {

  ::width = width;
  ::height = height;

  z_matryx_socket.connect(matryxEndpoint);
  z_layers_socket.bind(layersEndpoint);
  z_output_socket.bind(outputEndpoint);
}

void send(uint32_t *pixels) {
  zmq::const_buffer buffer(pixels, width * height * BPP);
  z_matryx_socket.send(buffer);

  zmq::message_t reply;
  static_cast<void>(z_matryx_socket.recv(reply));

  zmq::multipart_t message;
  message.addstr("output");
  message.addmem(pixels, width * height * BPP);
  message.send(z_output_socket);
}

void sendLayers(uint32_t *pixels, const int count) {
  zmq::multipart_t message;
  message.addtyp(count);
  message.addmem(pixels, width * height * BPP * count);
  message.send(z_layers_socket);
}
} // namespace pixelserver

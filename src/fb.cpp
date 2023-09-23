#include <iostream>

#include <fcntl.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

#include <zmq.hpp>

int main()
{
  int fbfd = open("/dev/fb0", O_RDWR);
  if (fbfd == -1)
  {
    std::cerr << "Error: cannot open framebuffer device.\n";
    return 1;
  }

  struct fb_var_screeninfo vinfo;
  ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo);

  int fb_width = vinfo.xres;
  int fb_height = vinfo.yres;
  int fb_bpp = vinfo.bits_per_pixel;
  int fb_bytes = fb_bpp / 8;

  std::cout << "Framebuffer: " << fb_width << "x" << fb_height << "x" << fb_bpp << "\n";

  int fb_data_size = fb_width * fb_height * fb_bytes;

  void *fbdata = mmap(0, fb_data_size, PROT_READ | PROT_WRITE, MAP_SHARED, fbfd, 0);
  if (fbdata == MAP_FAILED)
  {
    std::cerr << "Error: failed to map framebuffer device to memory.\n";
    return 1;
  }

  zmq::context_t z_context;
  zmq::socket_t z_socket(z_context, ZMQ_REQ);
  z_socket.connect("ipc:///var/run/matryx");

  std::vector<uint8_t> data(320 * 192 * 3);

  while (true)
  {
    for (auto y = 0; y < 192; y++)
    {
      for (auto x = 0; x < 320; x++)
      {
        data[(y * 320 + x) * 3 + 0] = ((uint8_t *)fbdata)[(y * fb_width + x) * fb_bytes + 2];
        data[(y * 320 + x) * 3 + 1] = ((uint8_t *)fbdata)[(y * fb_width + x) * fb_bytes + 1];
        data[(y * 320 + x) * 3 + 2] = ((uint8_t *)fbdata)[(y * fb_width + x) * fb_bytes + 0];
      }
    }

    zmq::const_buffer buffer(data.data(), data.size());
    z_socket.send(buffer);

    // recv
    zmq::message_t reply;
    z_socket.recv(&reply);
  }

  return 0;
}

#version 310 es

precision highp float;
precision highp int;
precision highp sampler2D;

out vec4 fragColor;

uniform sampler2D buffs[16];
uniform int buffCount;

// Image is made up of 16 320x192 buffers, displayed 4x4.
const ivec2 bufferSize = ivec2(320, 192);
const int bufferCount = 16;
const int bufferSplit = 4;

vec4 read(sampler2D buff, ivec2 buffCoord) {
  vec4 c = texelFetch(buff, buffCoord, 0);
  return c;
}

void main() {
  float m = 0.0;

  ivec2 xy = ivec2(gl_FragCoord.xy) / bufferSize;
  int i = xy.x + xy.y * bufferSplit;

  ivec2 buffCoord = ivec2(gl_FragCoord.xy) % bufferSize;
  fragColor = vec4(0.0, 0.0, 0.0, 1.0);

  fragColor = fragColor + read(buffs[0], buffCoord);
  fragColor = fragColor + read(buffs[1], buffCoord);
  fragColor = fragColor + read(buffs[2], buffCoord);
  fragColor = fragColor + read(buffs[3], buffCoord);
  fragColor = fragColor + read(buffs[4], buffCoord);
  fragColor = fragColor + read(buffs[5], buffCoord);
  fragColor = fragColor + read(buffs[6], buffCoord);
  fragColor = fragColor + read(buffs[7], buffCoord);
  fragColor = fragColor + read(buffs[8], buffCoord);
  fragColor = fragColor + read(buffs[9], buffCoord);
  fragColor = fragColor + read(buffs[10], buffCoord);
  fragColor = fragColor + read(buffs[11], buffCoord);
  fragColor = fragColor + read(buffs[12], buffCoord);
  fragColor = fragColor + read(buffs[13], buffCoord);
  fragColor = fragColor + read(buffs[14], buffCoord);
  fragColor = fragColor + read(buffs[15], buffCoord);
}

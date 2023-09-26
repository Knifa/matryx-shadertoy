#version 310 es

precision highp float;
precision highp int;
precision highp sampler2D;

uniform float time;
uniform float timeDelta;
uniform int frame;

layout (location = 0) out highp vec4 fragColor;
layout (location = 1) out highp vec4 fragColor2;

uniform sampler2D buffPrev;

const vec2 resolution = vec2(320.0, 192.0);
const vec2 resolution_aspect = vec2(320.0 / 192.0, 1.0);

const float PI = 3.1415926535897932384626433832795;
const float PI2 = 6.283185307179586476925286766559;
const float PI_HALF = 1.5707963267948966192313216916398;

// =============================================================================

vec2 uv;
vec2 uv_asp;
vec2 uv_centered;
vec2 uv_centered_asp;
vec2 coord;

vec2 coord2uv(const vec2 coord) {
    return coord / resolution;
}

vec2 uv2coord(const vec2 uv) {
    return uv * resolution;
}

vec4 read_coord(sampler2D buff, vec2 coord) {
    return texelFetch(buff, ivec2(coord), 0);
}

// Wrap coordinates out of bounds.
vec4 read_coord_wrap(sampler2D buff, vec2 coord) {
    return read_coord(buff, mod(coord, resolution));
}

// Clamp (i.e., repeat last) coordinates out of bounds.
vec4 read_coord_clamp(sampler2D buff, vec2 coord) {
    coord = clamp(coord, vec2(0.0), resolution - 1.0);
    return read_coord(buff, coord);
}

// Mirror coordinates out of bounds.
vec4 read_coord_mirror(sampler2D buff, vec2 coord) {
    coord = abs(coord);
    coord = resolution - abs(mod(coord, resolution * 2.0) - resolution);
    return read_coord(buff, coord);
}

// Return default value out of bounds.
vec4 read_coord_default(sampler2D buff, vec2 coord, vec4 default_value) {
    if (coord.x < 0.0 || coord.x >= resolution.x || coord.y < 0.0 || coord.y >= resolution.y) {
        return default_value;
    }

    return read_coord(buff, coord);
}

// Always return 0.0 out of bounds.
vec4 read_coord_0(sampler2D buff, vec2 coord) {
    return read_coord_default(buff, coord, vec4(0.0, 0.0, 0.0, 0.0));
}

// Always return 1.0 out of bounds.
vec4 read_coord_1(sampler2D buff, vec2 coord) {
    return read_coord_default(buff, coord, vec4(1.0, 1.0, 1.0, 1.0));
}


// =============================================================================

float mix_polar(float a, float b, float t) {
    float diff = mod(b - a + PI, PI2) - PI;
    return a + diff * t;
}

float remap(float value, float l, float h, float new_l, float new_h) {
    return (value - l) / (h - l) * (new_h - new_l) + new_l;
}

float remap(float value, float l, float h) {
    return remap(value, l, h, 0.0, 1.0);
}

// =============================================================================

float unpack_float(vec4 p) {
    int a = int(p.a * 255.0);
    int b = int(p.b * 255.0);
    int g = int(p.g * 255.0);
    int r = int(p.r * 255.0);

    int value = a | (b << 8) | (g << 16) | (r << 24);

    return intBitsToFloat(value);
}

vec4 pack_float(float v) {
    int bits = floatBitsToInt(v);

    int a = bits & int(0xFF);
    int b = (bits >> 8) & int(0xFF);
    int g = (bits >> 16) & int(0xFF);
    int r = (bits >> 24) & int(0xFF);

    return vec4(float(r) / 255.0, float(g) / 255.0, float(b) / 255.0, float(a) / 255.0);
}

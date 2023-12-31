#version 300 es

precision highp float;
precision highp int;
precision highp sampler2D;

uniform float time;
uniform float timeDelta;
uniform int frame;
uniform vec2 resolution;

layout (location = 0) out highp vec4 fragColor;
layout (location = 1) out highp vec4 fragColor2;

uniform sampler2D buffPrev;
uniform sampler2D buffThis;

vec2 resolution_aspect = vec2(0.0);

const float PI = 3.1415926535897932384626433832795;
const float PI2 = 6.283185307179586476925286766559;
const float PI_HALF = 1.5707963267948966192313216916398;

const float PHI = 1.6180339887498948482045868343656;
const float PHI_INV_A = 0.6180339887498948482045868343656;
const float PHI_INV_B = 0.3819660112501051517954131656344;

const float SQRT2 = 1.4142135623730950488016887242097;

const vec2 ZERO2 = vec2(0.0, 0.0);
const vec3 ZERO3 = vec3(0.0, 0.0, 0.0);
const vec4 ZERO4 = vec4(0.0, 0.0, 0.0, 0.0);

const vec2 ONE2 = vec2(1.0, 1.0);
const vec3 ONE3 = vec3(1.0, 1.0, 1.0);
const vec4 ONE4 = vec4(1.0, 1.0, 1.0, 1.0);

// =============================================================================

vec2 uv = ZERO2;
vec2 uv_asp = ZERO2;
vec2 uv_centered = ZERO2;
vec2 uv_centered_asp = ZERO2;
vec2 coord = ZERO2;

vec2 coord2uv(const vec2 coord) {
    return coord / resolution;
}

vec2 uv2coord(const vec2 uv) {
    return uv * resolution;
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
    return clamp(remap(value, 0.0, 1.0, l, h), l, h);
}

float norm(float value, float l, float h) {
    return clamp(remap(value, l, h, 0.0, 1.0), 0.0, 1.0);
}

// =============================================================================

float wrap(float value, float l, float h) {
    return mod(value - l, h - l) + l;
}

vec2 wrap(vec2 value, vec2 l, vec2 h) {
    return mod(value - l, h - l) + l;
}

float mirror(float value, float l, float h) {
    float range = h - l;
    float v = mod(value - l, range * 2.0);
    if (v > range) {
        v = range * 2.0 - v;
    }
    return v + l;
}

vec2 mirror(vec2 value, vec2 l, vec2 h) {
    vec2 range = h - l;
    vec2 v = mod(value - l, range * 2.0);
    vec2 m = step(range, v);
    v = mix(v, range * 2.0 - v, m);
    return v + l;
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

// =============================================================================

float time_norm(float seconds)
{
    return time * (1.0 / seconds);
}

float time_tan(float seconds)
{
    return time_norm(seconds) * PI2;
}

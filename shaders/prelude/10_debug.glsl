vec4 debug_out(vec2 x) {
  return vec4(x, 0.0, 1.0);
}

vec4 debug_out(vec3 x) {
  return vec4(x, 1.0);
}

vec4 debug_out(vec4 x) {
  return x;
}

// =============================================================================

vec4 debug_out(float x) {
  return vec4(x, 0.0, 0.0, 1.0);
}

vec4 debug_out(float x, float y) {
  return vec4(x, y, 0.0, 1.0);
}

vec4 debug_out(float x, float y, float z) {
  return vec4(x, y, z, 1.0);
}

vec4 debug_out(float x, float y, float z, float w) {
  return vec4(x, y, z, w);
}

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

vec4 read_coord_bilinear(sampler2D buff, vec2 coord) {
  coord += 0.5;

  vec2 coord_floor = floor(coord);
  vec2 coord_frac = fract(coord);

  vec4 c00 = read_coord_wrap(buff, coord_floor);
  vec4 c10 = read_coord_wrap(buff, coord_floor + vec2(1.0, 0.0));
  vec4 c01 = read_coord_wrap(buff, coord_floor + vec2(0.0, 1.0));
  vec4 c11 = read_coord_wrap(buff, coord_floor + vec2(1.0, 1.0));

  vec4 c0 = mix(c00, c10, coord_frac.x);
  vec4 c1 = mix(c01, c11, coord_frac.x);

  return mix(c0, c1, coord_frac.y);
}

vec4 read_uv_bilinear(sampler2D buff, vec2 uv) {
  return read_coord_bilinear(buff, uv * resolution);
}

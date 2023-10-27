vec4 render() {
  vec2 coord_ = coord / SCALE;

  return read_coord(buffPrev, coord_);
}

vec4 render() {
  if (frame % 4 != 0) {
    return read_coord(buffThis, coord);
  }

  vec2 push = vec2(
    1.0 * sin(time_tan(30.0)),
    1.0 * cos(time_tan(30.0))
  );

  vec4 last = read_coord_bilinear(buffThis, coord + push);
  vec4 new = read_coord(buff01, coord);

  return mix(last, new, 0.025) + new;
}

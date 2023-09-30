vec4 render() {
  // float x = remap(uv.x, 0.25, 0.75);
  float x = uv.x;
  if (x < 0.0 || x > 1.0) {
    return ZERO4;
  }

  // float y = curve_interpolate_linear(
  //   x,
  //   curve_make_points(
  //     vec4(0.0, 0.0, ZERO2),
  //     vec4(0.25, 0.1, ZERO2),
  //     vec4(0.5, 0.25, ZERO2),
  //     vec4(0.6, 0.5, ZERO2),
  //     vec4(0.7, 0.75, ZERO2),
  //     vec4(0.9, 0.95, ZERO2),
  //     vec4(1.0, 1.0, ZERO2)
  //   )
  // );

  vec2 p1 = vec2(0.0, 1.0);
  vec2 p2 = vec2(1.0, 0.0);

  vec2 p0 = ZERO2;
  vec2 p3 = ONE2;

  // const int point_count = 256;

  // vec2 points[point_count];
  // for (int i = 0; i < point_count; i++) {
  //   float t = float(i) / float(point_count - 1);
  //   points[i] = curve_cubic_beizer(
  //     t,
  //     p0,
  //     p1,
  //     p2,
  //     p3
  //   );
  // }

  // for (int i = 0; i < point_count; i++) {
  //   vec2 p = points[i];
  //   float d = distance(uv, p);
  //   if (d < 0.01) {
  //     return vec4(1.0, 0.0, 0.0, 1.0);
  //   }
  // }

  float y = curve_interpolate_beizer(
    x,
    p1,
    p2
  );

  vec2 p = vec2(x, y);
  if (distance(uv, p) < 0.01) {
    return vec4(1.0, 0.0, 0.0, 1.0);
  }

  return ZERO4;
}

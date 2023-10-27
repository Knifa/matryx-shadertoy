vec4 render() {
  vec4 life4 = read_coord(buffPrev, coord);
  float life = life4.r;

  float l = life;
  float c = pow(life, 2.0) * 0.2;
  float h = life * 300.0 + time_norm(30.0) * 360.0;

  h += uv.y * 120.0 + uv.x * 30.0;
  h += sin(time_tan(30.0) + uv.x * 1.1) * 30.0;
  h += cos(time_tan(30.0) + uv.y * 0.9) * 30.0;

  vec3 o = OKLCH_TO_SRGB(vec3(
    l,
    c,
    h
  ));

  return vec4(o, 1.0);
}

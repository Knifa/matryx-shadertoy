vec4 render()
{
  wave_init();

  // ===========================================================================

  float l, c, h;
  vec2 uv_ = uv_centered;

  // wave_reflect(uv_);

  // ===========================================================================

  float x = read_coord(buffPrev, coord).x;

  x = curve_interpolate_beizer(
    x,
    vec2(0.5, 0.0),
    vec2(0.5, 1.0)
  );

  x = clamp(x, 0.0, 1.0);

  // ===========================================================================

  float lx = pow(x, 1.0);

  l = remap(
    lx,
    0.0, 1.0,
    0.0, 1.0
  );

  // Apply L split.
  // l = mix(
  //   l,
  //   mix(l, pow(l * 1.25, 1.5), pow(split_pct, 1.0 / 2.0)),
  //   split_step
  // );

  // Fade at bottom.
  // l = mix(
  //   l,
  //   smoothstep(0.25, 0.5, l) * pow(l, 2.0),
  //   split_pct
  // );

  // l = mix(
  //   l,
  //   mix(
  //     l,
  //     pow(l, 2.0),
  //     split_pct
  //   ),
  //   split_step
  // );


  // ===========================================================================

  float cx = pow(x, 1.5);

  c = remap(
      cx,
      0.0, 1.0,
      0.0, 0.15
  );

  // c *= remap(
  //   (
  //     cos(uv_.y * (PI / 2.35) + time_norm(45.0))
  //     * sin(uv_.x * (PI / 4.6) + time_norm(47.0))
  //     * cos(uv_.y * (PI / 2.5) + time_norm(69.0))
  //   ), -1.0, 1.0, 0.5, 1.0
  // );

  // Apply C split.
  // c = mix(
  //   c,
  //   c * 0.5,
  //   split_pct
  // );

  // ===========================================================================

  h = pow(x, 1.5) * 180.0;

  h +=
    (
      sin(uv_.y * (PI / 3.0) + time_norm(55.0))
      + cos(uv_.x * (PI / 7.0) + time_norm(65.0))
    ) * 270.0;
  h += uv_.y * 60.0 + uv_.x * 40.0;
  h += time_norm(60.0) * 360.0;

  // Apply H split.
  // h = mix(
  //   h,
  //   h + 30.0,
  //   pow(split_pct, 1.0 / 2.0)
  // );

  // ===========================================================================

  l = clamp(l, 0.0, 1.0);
  c = clamp(c, 0.0, 1.0);
  h = mod(h, 360.0);

  vec3 rgb = OKLCH_TO_SRGB(vec3(l, c, h));

  // rgb = mix(
  //   rgb,
  //   ZERO3,
  //   split_pct
  // );

  // ===========================================================================

  return vec4(rgb, 1.0);

  // ===========================================================================

  // return vec4(OKLCH_TO_SRGB(vec3(1.0 - l, c, h)), 1.0);
  // return vec4(OKLCH_TO_SRGB(vec3(l, 0.3 - c, h)), 1.0);
  // return vec4(OKLCH_TO_SRGB(vec3(1.0 - l, 0.3 - c, h)), 1.0);

  // return vec4(OKLCH_TO_SRGB(vec3(1.0, 0.5, h)), 1.0);
  // return vec4(LCH_TO_SRGB(vec3(50.0, 50.0, h)), 1.0);
  // return vec4(h / 360.0, h / 360.0, h / 360.0, 1.0);
  // return vec4(uv.x, 0.0, 0.0, 1.0);

  // return vec4(LAB_TO_SRGB(
  //     vec3(
  //         75.0,
  //         cos(uv_centered_asp.x * PI + time) * (1.0 - l) * 100.0,
  //         sin(uv_centered_asp.y * PI + time) * (1.0 - l) * 100.0
  //     )
  // ), 1.0);
  // return vec4(LAB_TO_SRGB(vec3(l * 75.0, uv_centered_asp.x * 100.0, uv_centered_asp.y * 100.0)), 1.0);
};

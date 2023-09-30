vec4 render() {
  wave_init();

  // ===========================================================================

  vec2 uv_ = uv_centered;

  // ===========================================================================

  // Perspective

  uv_.y = mix(
    uv_.y,
    mix(
      uv_.y * 0.75,
      uv_.y * 0.25,
      pow(split_pct, 1.0 / 3.0)
    ),
    split_step
  );

  // ===========================================================================

  // Ripple.

  uv_.y = mix(
    uv_.y,
    (
      uv_.y +
      (
        sin(time_tan(120.0) + pow(split_pct, 1.0 / 2.0) * PI2 * 0.5)
        * 0.1 * pow(split_pct, 1.0 / 3.0)
      )
    ),
    split_step
  );

  // ===========================================================================

  // Reflect

  uv_.x = mix(
    uv_.x,
    mix(SPLIT_CENTERED, 0.25, pow(split_pct, 1.0 / 3.0)),
    split_step
  );

  uv_.x = mix(
    uv_.x,
    uv_.x - (
      (
        sin(time_tan(60.0) + pow(split_pct, 1.0 / 1.0) * PI2 * 1.0)
        * 0.5
        + 0.5
      )
      * pow(split_pct, 1.0 / 1.0)
      * 0.025
    ),
    split_step
  );

  // ===========================================================================

  vec2 coord_ = uv_ * resolution + resolution / 2.0;
  vec4 o = read_coord_bilinear(
    buffPrev,
    coord_
  );

  return vec4(o.rgb, 1.0);
}

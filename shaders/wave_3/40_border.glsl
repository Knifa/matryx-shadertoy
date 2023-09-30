const float crop = 0.0;
const float smoothCrop = 32.0;

vec4 render() {
  vec4 o = read_coord(buffPrev, coord);

  vec2 crop_step = (
    vec2(
      step(crop, coord.x),
      step(crop, coord.y)
    )
    *
    (
      ONE2 - vec2(
        step(resolution.x - crop, coord.x),
        step(resolution.y - crop, coord.y)
      )
    )
  );

  o.rgb *= crop_step.x * crop_step.y;

  // With smoothstep.
  vec2 smooth_step = (
    vec2(
      smoothstep(crop, smoothCrop, coord.x),
      smoothstep(crop, smoothCrop, coord.y)
    )
    *
    (
      ONE2 - vec2(
        smoothstep(resolution.x - smoothCrop, resolution.x - crop, coord.x),
        smoothstep(resolution.y - smoothCrop, resolution.y - crop, coord.y)
      )
    )
  );

  // With linear interp.
  // float t_x = clamp((coord.x - crop) / (smoothCrop - crop), 0.0, 1.0);
  // float t_y = clamp((coord.y - crop) / (smoothCrop - crop), 0.0, 1.0);
  // float t_x_ = clamp((resolution.x - coord.x - crop) / (smoothCrop - crop), 0.0, 1.0);
  // float t_y_ = clamp((resolution.y - coord.y - crop) / (smoothCrop - crop), 0.0, 1.0);
  // vec2 smooth_step = (
  //   vec2(
  //     t_x_,
  //     t_y_
  //   )
  //   *
  //   (
  //     vec2(
  //       t_x,
  //       t_y
  //     )
  //   )
  // );

  float smooth_step_ = smooth_step.x * smooth_step.y;

  vec3 u = SRGB_TO_LCH(o.rgb);

  u.r = u.r * remap(pow(smooth_step_, 1.0 / 4.0), 0.0, 1.0, -0.2, 1.0);
  u.g = u.g * remap(pow(smooth_step_, 1.0), 0.0, 1.0, 0.25, 1.0);
  // u.b = u.b * remap(pow(smooth_step_, 1.0), 0.0, 1.0, 0.75, 1.25);

  u = LCH_TO_SRGB(u);
  return vec4(u.rgb, 1.0);

  // o.rgb = o.rgb * smooth_step_;
  // return vec4(o.rgb, 1.0);
}

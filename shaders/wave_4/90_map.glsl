vec4 render()
{
  vec4 trail = read_wrapped_coord(buff4, coord);
  float l = trail.x;
  float c = trail.y;

  // l = pow(l, 1.0 / 9.0);
  // c = pow(c, 1.0 / 13.0);

  // c = (1.0 - c) * 0.95 + 0.05;

  // // float h = (1.0 - (1.0 - pow(1.0 - v, 2.0))) * 0.75;
  // float h = (1.0 - v) * 0.8;

  // // float s = 1.0 - smoothstep(0.8, 1.0, v);
  // float s = 1.0;

  // vec3 rgb = HSV_TO_SRGB(vec3(h, s, smoothstep(0.0, 0.075, v)));
  // vec3 rgb = OKLCH_TO_SRGB(vec3(smoothstep(0.0, 0.075, v) * 0.66, 0.25, h * 360.0));

  // vec3 rgb = OKLCH_TO_SRGB(vec3(0.5, 0.25, c * 270.0));

  // vec3 rgb = turbo_colormap(c);

  Gradient g = make_gradient(
    make_gradient_stop(0.025, vec3(1.0, 0.0, 0.0)),
    make_gradient_stop(0.14, vec3(1.0, 0.0, 0.0)),
    make_gradient_stop(0.28, vec3(1.0, 1.0, 0.0)),
    make_gradient_stop(0.42, vec3(0.0, 1.0, 0.0)),
    make_gradient_stop(0.56, vec3(0.0, 1.0, 1.0)),
    make_gradient_stop(0.70, vec3(0.0, 0.0, 1.0)),
    make_gradient_stop(0.84, vec3(1.0, 0.0, 1.0)),
    make_gradient_stop(1.0, vec3(1.0, 1.0, 1.0))
  );

  // vec3 rgb = mix_gradient(g, c);
  // rgb = rgb * smoothstep(0.0, 0.05, l);

  float h = time;

  Gradient okg = make_gradient(
    make_gradient_stop(0.0, OKLCH_TO_OKLAB(vec3(0.00, 0.00, 0.00 + h))),
    make_gradient_stop(0.25, OKLCH_TO_OKLAB(vec3(0.5, 0.25, 180.00 + h))),
    make_gradient_stop(0.75, OKLCH_TO_OKLAB(vec3(1.0, 0.35, 240.00 + h))),
    make_gradient_stop(1.0, OKLCH_TO_OKLAB(vec3(1.00, 0.15, 270.00 + h)))
  );

  vec3 ok = mix_gradient(okg, l);
  vec3 rgb = OKLAB_TO_SRGB(ok);
  // rgb = SRGB_TO_RGB(rgb);

  return vec4(rgb, 1.0);
};

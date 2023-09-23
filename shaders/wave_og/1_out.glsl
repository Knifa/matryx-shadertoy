vec4 render()
{
  float v = texelFetch(buffPrev, ivec2(gl_FragCoord.xy), 0).x;
  v = pow(v, 1.0);

  float l = pow(v, 1.0);
  float c = 0.1;

  float h = (v + time * 0.1) * 360.0;
  h = mod(h, 360.0);

  vec3 o = OKLCH_TO_SRGB(vec3(l, c, h));
  // o = SRGB_TO_RGB(o);

  return vec4(vec3(o), 1.0);
};

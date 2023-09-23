vec4 render()
{
  vec4 t = texelFetch(buffOut, ivec2(gl_FragCoord.xy), 0);

  t = pow(t, vec4(2.0));

  t.r = t.x * 1.0;
  t.g = t.x * 1.0;
  t.b = t.x * 1.0;

  t = clamp(t, 0.0, 1.0);
  return vec4(t.rgb, 1.0);
};

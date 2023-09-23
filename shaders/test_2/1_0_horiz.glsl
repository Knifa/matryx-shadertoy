vec4 render(vec2 uv)
{
  ivec2 p = ivec2(gl_FragCoord.xy);
  vec4 t = texelFetch(buffPrev, p, 0);

  const int n = 7;

  for (int i = 1; i < n; i++) {
    t += texelFetch(buffPrev, p + ivec2(i, 0), 0);
    t += texelFetch(buffPrev, p - ivec2(i, 0), 0);
  }

  t = t / float(n * 2 + 1);

  return vec4(t.rgb, 1.0);
};

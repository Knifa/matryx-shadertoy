vec4 render(vec2 uv)
{
  ivec2 p = ivec2(gl_FragCoord.xy);

  // Checkerboard Pattern
  int x = int(p.x / 10);
  int y = int(p.y / 10);

  if (x % 2 == 0 && y % 2 == 0)
  {
    return vec4(0.0, 1.0, 0.0, 1.0);
  }
  else if (x % 2 == 1 && y % 2 == 1)
  {
    return vec4(1.0, 0.0, 0.0, 1.0);
  }
  else
  {
    return vec4(0.0, 0.0, 0.0, 1.0);
  }
};

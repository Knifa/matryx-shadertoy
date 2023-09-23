vec4 render()
{
  vec4 o = texture(buffGrid, uv);
  return vec4(step(THRESH, o.rgb) * o.rgb, 1.0);
}

vec4 render()
{
  vec4 o = read_wrapped_coord(buff1, coord);
  return vec4(o.rgb, 1.0);
};

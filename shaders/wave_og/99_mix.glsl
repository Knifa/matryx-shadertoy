vec4 render()
{
  vec4 o = read_coord_wrap(buff1, coord);
  return vec4(o.rgb, 1.0);
};

vec4 render()
{
  vec4 new = read_coord_wrap(buff3, coord);
  float v = clamp(new.x, 0.0, 1.0);

  const float clip = 0.001;
  float l = step(clip, v) * remap(v, clip, 1.0);
  float c = step(clip, v);

  vec4 last = read_coord_wrap(buff4, coord);
  float last_l = last.x;
  float last_c = last.y;

  float fade = 0.99;
  float new_l = l + last_l * fade;
  float new_c = c + last_c * fade;

  new_l = clamp(new_l, 0.0, 1.0);
  new_c = clamp(new_c, 0.0, 1.0);

  return vec4(new_l, new_c, 0.0, 1.0);
};

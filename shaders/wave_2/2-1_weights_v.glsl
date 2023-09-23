vec4 render()
{
  vec4 o = vec4(0.0);
  float weight = 0.0;

  for (int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++) {
    float w = get_weight(float(i) / float(SEARCH_RADIUS));
    weight += w;

    vec4 t = texture(buffPrev, coord2uv(coord + vec2(0.0, i)));
    o = o + t * w;
  }

  o /= weight;
  return vec4(o.rgb, 1.0);
};

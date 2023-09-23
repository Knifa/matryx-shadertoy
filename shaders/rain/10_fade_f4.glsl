vec4 render() {
  vec4 new = texelFetch(buff00, ivec2(coord), 0);
  vec4 last = texelFetch(buff10, ivec2(coord), 0);

  return new + last * 0.9;
}

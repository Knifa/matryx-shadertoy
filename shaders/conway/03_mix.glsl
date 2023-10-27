vec4 render() {
  vec4 life = read_coord(buff01_scale, coord);
  vec4 trail = read_coord(buff02_trail, coord);

  return mix(life, trail, 0.95);
}

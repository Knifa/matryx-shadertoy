vec3 init() {
  float x = rand_random();

  return vec3(x);
}

vec3 read(vec2 relCoord) {
  vec2 coord_ = coord + relCoord;
  coord_ = wrap(coord_, ZERO2, resolution / SCALE);

  return read_coord(buff00_life, coord_).xyz;
}

vec3 gen() {
  vec3 lastBuff = read(vec2(0, 0));

  int lastCell = int(lastBuff.x > 0.5);
  int nextCell = 0;

  int neighbors = 0;
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <=1; j++) {
      if (i == 0 && j == 0) {
        continue;
      }

      vec3 neighbor = read(vec2(i, j));

      if (neighbor.x > 0.5) {
        neighbors++;
      }
    }
  }

  if (lastCell == 1) {
    if (neighbors < 2 || neighbors > 3) {
      nextCell = 0;
    } else {
      nextCell = 1;
    }
  } else {
    if (neighbors == 3) {
      nextCell = 1;
    } else {
      nextCell = 0;
    }
  }

  return vec3(nextCell);
}

vec4 render() {
  if (coord.x > resolution.x / SCALE || coord.y > resolution.y / SCALE) {
    discard;
  }

  if (frame == 0) {
    return vec4(init(), 1.0);
  }

  if (frame % 4 != 0) {
    return read_coord(buffThis, coord);
  }

  return vec4(gen(), 1.0);
}

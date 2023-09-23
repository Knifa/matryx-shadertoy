const int MEDIAN_SIZE = 13;
// const int MEDIAN_SIZE = 5;

vec4 read(int x, int y) {
  return read_wrapped_coord(buff0, coord + vec2(x, y));
}

vec4 render() {
  float values[MEDIAN_SIZE];

  // // Circle median, 5x5.
  // // 0 0 1 0 0
  // // 0 1 1 1 0
  // // 1 1 1 1 1
  // // 0 1 1 1 0
  // // 0 0 1 0 0
  // // Total active = 13

  values[0] = read(-2, 0).x;
  values[1] = read(-1, -1).x;
  values[2] = read(-1, 0).x;
  values[3] = read(-1, 1).x;
  values[4] = read(0, -2).x;
  values[5] = read(0, -1).x;
  values[6] = read(0, 0).x;
  values[7] = read(0, 1).x;
  values[8] = read(0, 2).x;
  values[9] = read(1, -1).x;
  values[10] = read(1, 0).x;
  values[11] = read(1, 1).x;
  values[12] = read(2, 0).x;

  // Circle Median, 3x3.
  // 0 1 0
  // 1 1 1
  // 0 1 0
  // Total active = 5

  // values[0] = read(-1, 0).x;
  // values[1] = read(0, -1).x;
  // values[2] = read(0, 0).x;
  // values[3] = read(0, 1).x;
  // values[4] = read(1, 0).x;

  // Sort.
  for (int i = 0; i < MEDIAN_SIZE; i++) {
    for (int j = i + 1; j < MEDIAN_SIZE; j++) {
      if (values[i] > values[j]) {
        float temp = values[i];
        values[i] = values[j];
        values[j] = temp;
      }
    }
  }

  return vec4(vec3(values[MEDIAN_SIZE / 2]), 1.0);
}

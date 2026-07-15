const int SEARCH_RADIUS = 7;
const int SEARCH_DIAMETER = 2 * SEARCH_RADIUS + 1;

const float SEARCH_RADIUS_F = float(SEARCH_RADIUS);
const float SEARCH_DIAMETER_F = float(SEARCH_DIAMETER);

const float FADE_SCALE = 0.2;

const float FADE_THRESHOLD_LOWER = -1.0;
const float FADE_THRESHOLD_UPPER = 3.0;

const float STAY_THRESHOLD_LOWER = 0.6;
const float STAY_THRESHOLD_UPPER = STAY_THRESHOLD_LOWER;
// const float STAY_THRESHOLD_UPPER = 0.49;

const float TAKEOVER_THRESHOLD_LOWER = STAY_THRESHOLD_LOWER * 1.10;
const float TAKEOVER_THRESHOLD_UPPER = STAY_THRESHOLD_LOWER * 1.20;
// const float TAKEOVER_THRESHOLD_UPPER = 0.54;

const float stepDelta = 0.002;

float read(vec2 coord_) {
  coord_ = coord + coord_;

  // if (coord_.y > SPLIT_BLEND_B * resolution.y) {
  //     return rand_random();
  // } else if (coord_.y < 0.0) {
  //     return rand_random();
  // }

  // uv_ -= 0.5;
  // uv_ *= resolution_aspect;

  // ivec2 c_coord = ivec2(uv_ * resolution);
  // float size = 0.25 * (sin(time * (1.0 / 120.0) * PI2) + 1.0) + 0.025;
  // float outlineSize = size * 1.05;

  // if (
  //     in_bounding_box(c_coord, ivec2(-size * 3, 0), ivec2(size, size))
  //     || in_bounding_box(c_coord, ivec2(0, 0), ivec2(size, size))
  //     || in_bounding_box(c_coord, ivec2(size * 3, 0), ivec2(size, size)))
  // {
  //     return 0.0;
  // }

  // if (in_bounding_box(c_coord, ivec2(-size * 3, 0), ivec2(outlineSize, outlineSize))
  //     || in_bounding_box(c_coord, ivec2(0, 0), ivec2(outlineSize, outlineSize))
  //     || in_bounding_box(c_coord, ivec2(size * 3, 0), ivec2(outlineSize, outlineSize)))
  // {
  //     return 1.0;
  // }

  // if (in_bounding_circle(uv_, vec2(0.0, 0.0), size))
  // {
  //     return 0.0;
  // }

  // if (in_bounding_circle(uv_, vec2(-0.5, 0.0), outlineSize))
  // {
  //     return 1.0;
  // }

  // vec2 poly_coords[8] = vec2[8](
  //     vec2(-0.1, -0.1),
  //     vec2(-0.1, 0.1),
  //     vec2(0.1, 0.1),
  //     vec2(0.1, -0.1),
  //     vec2(0.0, 0.0),
  //     vec2(0.0, 0.0),
  //     vec2(0.0, 0.0),
  //     vec2(0.0, 0.0)
  // );

  // for (int i = 0; i < 4; i++) {
  //     poly_coords[i] *= mat2(cos(time), sin(time), -sin(time), cos(time));
  // }

  // if (in_bounding_polygon(uv_, poly_coords, 4)) {
  //     return 1.0;
  // }

  // return read_coord_wrap(buff00, coord_).r;
  // return read_coord_default(buff00, coord_, vec4(rand_random())).r;
  // return read_coord_mirror(buff00, coord_).r;

  // if (wave_outside_bounds(coord_)) {
  //   return wave_outside_bounds_value(coord_);
  // }

  // return read_coord_clamp(buff00, coord_).r;

  float xPush = time_norm(2.0);
  float yPush = time_norm(2.0);
  float _debugOffset = 0.0;

  if (coord_.y < _debugOffset) {
    coord_.x = mod(coord_.x - xPush, resolution.x);
    coord_.y = mod(coord_.y, resolution.y);

    coord_.y += _debugOffset;
  }

  if (coord_.x >= resolution.x - _debugOffset) {
    coord_.y = mod(coord_.y - yPush, resolution.y);
    coord_.x = mod(coord_.x, resolution.x);

    coord_.x -= _debugOffset;
  }

  if (coord_.y >= resolution.y - _debugOffset) {
    coord_.x = mod(coord_.x + xPush, resolution.x);
    coord_.y = mod(coord_.y, resolution.y);

    coord_.y -= _debugOffset;
  }

  if (coord_.x < _debugOffset) {
    coord_.y = mod(coord_.y + yPush, resolution.y);
    coord_.x = mod(coord_.x, resolution.x);

    coord_.x += _debugOffset;
  }



  // if (coord_.x < 0.0) {
  //   coord_.x = mod(coord_.x, resolution.x);
  //   coord_.y = mod(resolution.y - coord_.y - yPush, resolution.y);
  // }

  // if (coord_.x < 0.0) {
  //   coord_.x = mod(coord_.x, resolution.x);
  //   coord_.y = mod(resolution.y - coord_.y + yPush, resolution.y);
  // }

  return read_coord(buff00, coord_).r;
}

float grow() {
  float range_mul;
  // range_mul = sin(time_tan(600.0));
  // range_mul = 1.0 + range_mul * 0.1;
  range_mul = 1.0;

  float timeBoost;
  timeBoost = 0.2;
  if (time < 60.0) {
    timeBoost = timeBoost * 10.0;
    range_mul = 1.0;
  }
  timeBoost = 1.0;

  float lval = read(vec2(0.0, 0.0));

  // The random range being bigger here makes it more chaotic, generally.
  float val =
      lval * (1.0 - rand_range(
        FADE_THRESHOLD_LOWER * FADE_SCALE,
        FADE_THRESHOLD_UPPER * FADE_SCALE
      ) * stepDelta * timeBoost);
    val = clamp(val, 0.0, 1.0);

  // higher values here induce more smoothing and like more spirals
  // there needs to be a gap between the value below though.
  // kind of like a "contrast" value????
  if (val >= rand_range(STAY_THRESHOLD_LOWER, STAY_THRESHOLD_UPPER) * range_mul) {
    return val;
  }


  float nval = 0.0;
  float n = 0.0;

  for (int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++) {
    for (int j = -SEARCH_RADIUS; j <= SEARCH_RADIUS; j++) {
      // if (i == 0 && j == 0) {
      //   continue;
      // }

      float lvn = read(vec2(float(i), float(j)));

      // float ni = float(i) / SEARCH_RADIUS_F;
      // float nj = float(j) / SEARCH_RADIUS_F;

      float dist = (
        distance(vec2(0.0, 0.0), vec2(i, j))
         / SEARCH_RADIUS_F
         / sqrt(2.0)
      );

      float weight = 1.0;

      // weight = 1.0 - ni * ni - nj * nj; // bugged, sharp corners (og)
      // weight = 1.0 - sqrt(ni * ni + nj * nj); // needs large radius
      // weight = SEARCH_DIAMETER_F - sqrt(ni * ni + nj * nj); // wtf
      // weight = SEARCH_DIAMETER_F - sqrt(ni * ni + nj * nj) * (SEARCH_RADIUS_F - 1.0); // wtf but
      // bigger spirals!? weight = 1.0; // functionally the same as the one above, i think

      // weight = 1.0;
      weight = 1.0 - dist;
      // weight = dist; // as in, further away is better

      // weight = 1.0 - (pow(dist, 1.0) * 0.8);
      // weight = pow(weight, 1.0);

      // higher values here mean smoother growth, kind of like zooming in
      // randomness here is very important to keep it alive
      float lvn_threshold =
          rand_range(TAKEOVER_THRESHOLD_LOWER, TAKEOVER_THRESHOLD_UPPER) * range_mul;
      // weight = weight * smoothstep(
      //     lvn_threshold * 0.95,
      //     lvn_threshold * 1.05,
      //     lvn
      // );
      weight = weight * step(lvn_threshold, lvn);

      // having a higher weight randomization here seems to make things worse?
      // like it decays quicker
      // val += lvn * rand_range(0.95, 1.05) * weight;
      nval += lvn * weight;
      n += weight;
    }
  }

  if (n == 0.0) {
    val = 1.0;
  } else {
    val = (nval) / n;
  }

  val = clamp(val, 0.0, 1.0);

  return val;
}

float init() {
  float x = rand_random();
  return x;
}

vec4 render() {
  if (wave_outside_bounds()) {
    return vec4(vec3(read(ZERO2)), 1.0);
  }

  // if (uv.y > SPLIT_BLEND_B) {
  //     discard;
  // }

  float o;
  if (frame == 0) {
    o = init();
  } else {
    o = grow();
  }

  return vec4(vec3(o), 1.0);
}

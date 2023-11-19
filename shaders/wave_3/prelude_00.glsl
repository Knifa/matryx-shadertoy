const float SPLIT = 0.66;
const float SPLIT_CENTERED = SPLIT - 0.5;

const float SPLIT_INV = 1.0 - SPLIT;
const float SPLIT_INV_CENTERED = SPLIT_INV - 0.5;

const float SPLIT_GAP = 0.05;
const float SPLIT_BLEND_A = SPLIT - SPLIT_GAP;
const float SPLIT_BLEND_B = SPLIT + SPLIT_GAP;

const float BOUND_INSET = -1.0;

float split_step_hard;
float split_step;
float split_pct;

// =============================================================================

void wave_init() {
  split_step_hard = step(0.0, SPLIT_BLEND_A);
  split_step = smoothstep(SPLIT_BLEND_A, SPLIT_BLEND_B, uv.y);
  split_pct = norm(uv.y, SPLIT_BLEND_A, 1.0) * split_step;
}

// =============================================================================

const float _WAVE_REFLEC_POW = 1.0 / 2.0;

void wave_reflect(inout vec2 uv_) {
  float split_pct_pow = pow(split_pct, _WAVE_REFLEC_POW);

  uv_.x = mix(
    uv_.x,
    mix(
      uv_.x * 0.8,
      uv_.x * 0.2,
      split_pct_pow
    ),
    split_step
  );

  // ===========================================================================

  // Ripple.

  uv_.x = mix(
    uv_.x,
    (
      uv_.x +
      (
        sin(time_tan(120.0) + split_pct * PI2 * 2.5)
        * 0.025 * split_pct_pow
      )
    ),
    split_step
  );

  // ===========================================================================

  // Reflect

  uv_.y = mix(
    uv_.y,
    mix(SPLIT_CENTERED, SPLIT_INV_CENTERED, split_pct_pow),
    split_step
  );

  // Refract?

  uv_.y = mix(
    uv_.y,
    uv_.y - (
      (
        sin(time_tan(120.0) + split_pct * PI2 * 2.5)
        * 0.5
        + 0.5
      )
      * split_pct_pow
      * 0.05
    ),
    split_step
  );
}

// =============================================================================

float wave_outside_bounds_value(in vec2 coord_) {
  vec2 uv_;
  uv_ = (coord / resolution) - 0.5;
  uv_ *= resolution_aspect;

  float outside;

  outside = (
      sin((uv_.x + uv_.y) * PI2 * 10.0 + time_tan(300.0))
  );

  outside = norm(outside, -1.0, 1.0);
  outside = smoothstep(0.25, 0.75, outside);
  outside = remap(outside, 0.25, 0.75);


  return outside;
}

bool wave_outside_bounds(in vec2 coord_) {
  float bound_inset_inv_x = resolution.x - BOUND_INSET;
  float bound_inset_inv_y = resolution.y - BOUND_INSET;

  return (
    coord_.x < BOUND_INSET ||
    coord_.x > bound_inset_inv_x ||
    coord_.y < BOUND_INSET ||
    coord_.y > bound_inset_inv_y
  );
}

float wave_outside_bounds_value() {
  return wave_outside_bounds_value(coord);
}

bool wave_outside_bounds() {
  return wave_outside_bounds(coord);
}

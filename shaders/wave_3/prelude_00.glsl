const float SPLIT = 0.33;
const float SPLIT_CENTERED = SPLIT - 0.5;

const float SPLIT_INV = 1.0 - SPLIT;
const float SPLIT_INV_CENTERED = SPLIT_INV - 0.5;

const float SPLIT_GAP = 0.025;
const float SPLIT_BLEND_A = SPLIT - SPLIT_GAP;
const float SPLIT_BLEND_B = SPLIT + SPLIT_GAP;

float split_step_hard;
float split_step;
float split_pct;

// =============================================================================

void wave_init() {
  split_step_hard = 1.0 - step(0.0, uv.x - SPLIT);
  split_step = (
    1.0 - smoothstep(SPLIT_BLEND_A, SPLIT_BLEND_B, uv.x)
  );

  split_pct = (1.0 - norm(uv.x, 0.0, SPLIT)) * (1.0 - smoothstep(SPLIT_BLEND_A, SPLIT, uv.x));
}

// =============================================================================

const float _WAVE_REFLEC_POW = 1.0 / 2.0;

void wave_reflect(inout vec2 uv_) {
  float split_pct_pow = pow(split_pct, _WAVE_REFLEC_POW);

  uv_.y = mix(
    uv_.y,
    mix(
      uv_.y * 0.8,
      uv_.y * 0.1,
      split_pct_pow
    ),
    split_step
  );

  // ===========================================================================

  // Ripple.

  uv_.y = mix(
    uv_.y,
    (
      uv_.y +
      (
        sin(time_tan(120.0) + split_pct * PI2 * 1.05)
        * 0.025 * split_pct_pow
      )
    ),
    split_step
  );

  // ===========================================================================

  // Reflect

  uv_.x = mix(
    uv_.x,
    mix(SPLIT_CENTERED, SPLIT_INV_CENTERED, split_pct_pow),
    split_step
  );

  // Refract?

  uv_.x = mix(
    uv_.x,
    uv_.x - (
      (
        sin(time_tan(60.0) + split_pct * PI2 * 0.95)
        * 0.5
        + 0.5
      )
      * split_pct_pow
      * 0.01
    ),
    split_step
  );
}

const float SPLIT = PHI_INV_B;
const float SPLIT_CENTERED = SPLIT - 0.5;

const float SPLIT_INV = 1.0 - SPLIT;
const float SPLIT_INV_CENTERED = SPLIT_INV - 0.5;

const float SPLIT_BLEND_A = SPLIT * 0.8;
const float SPLIT_BLEND_B = SPLIT * 1.2;

float split_step_hard;
float split_step;
float split_pct;

void wave_init() {
  split_step_hard = 1.0 - step(0.0, uv.x - SPLIT);
  split_step = (
    1.0 - smoothstep(SPLIT_BLEND_A, SPLIT_BLEND_B, uv.x)
  );

  split_pct = (1.0 - norm(uv.x, 0.0, SPLIT)) * (1.0 - smoothstep(SPLIT_BLEND_A, SPLIT, uv.x));
}

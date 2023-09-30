const int curve_MAX_POINTS = 8;

struct curve_CurvePoints {
  vec4 points[curve_MAX_POINTS]; // X, Y, (M1, M2 or Angle, Length)
  int point_count;
};

curve_CurvePoints curve_make_points(vec4[curve_MAX_POINTS] points, int point_count)
{
  curve_CurvePoints curve_points;
  curve_points.point_count = point_count;
  for (int i = 0; i < point_count; i++) {
    curve_points.points[i] = points[i];
  }
  return curve_points;
}

curve_CurvePoints curve_make_points(vec4 p1, vec4 p2)
{
  return curve_make_points(vec4[curve_MAX_POINTS](
    p1,
    p2,
    ZERO4,
    ZERO4,
    ZERO4,
    ZERO4,
    ZERO4,
    ZERO4
  ), 2);
}

curve_CurvePoints curve_make_points(vec4 p1, vec4 p2, vec4 p3)
{
  return curve_make_points(vec4[curve_MAX_POINTS](
    p1,
    p2,
    p3,
    ZERO4,
    ZERO4,
    ZERO4,
    ZERO4,
    ZERO4
  ), 3);
}

curve_CurvePoints curve_make_points(vec4 p1, vec4 p2, vec4 p3, vec4 p4)
{
  return curve_make_points(vec4[curve_MAX_POINTS](
    p1,
    p2,
    p3,
    p4,
    ZERO4,
    ZERO4,
    ZERO4,
    ZERO4
  ), 4);
}

curve_CurvePoints curve_make_points(vec4 p1, vec4 p2, vec4 p3, vec4 p4, vec4 p5)
{
  return curve_make_points(vec4[curve_MAX_POINTS](
    p1,
    p2,
    p3,
    p4,
    p5,
    ZERO4,
    ZERO4,
    ZERO4
  ), 5);
}

curve_CurvePoints curve_make_points(vec4 p1, vec4 p2, vec4 p3, vec4 p4, vec4 p5, vec4 p6)
{
  return curve_make_points(vec4[curve_MAX_POINTS](
    p1,
    p2,
    p3,
    p4,
    p5,
    p6,
    ZERO4,
    ZERO4
  ), 6);
}

curve_CurvePoints curve_make_points(vec4 p1, vec4 p2, vec4 p3, vec4 p4, vec4 p5, vec4 p6, vec4 p7)
{
  return curve_make_points(vec4[curve_MAX_POINTS](
    p1,
    p2,
    p3,
    p4,
    p5,
    p6,
    p7,
    ZERO4
  ), 7);
}

curve_CurvePoints curve_make_points(vec4 p1, vec4 p2, vec4 p3, vec4 p4, vec4 p5, vec4 p6, vec4 p7, vec4 p8)
{
  return curve_make_points(vec4[curve_MAX_POINTS](
    p1,
    p2,
    p3,
    p4,
    p5,
    p6,
    p7,
    p8
  ), 8);
}

// =============================================================================


float curve_linear(float x, float y1, float y2)
{
  return mix(y1, y2, x);
}

float curve_cubic(float x, float y1, float y2)
{
  return mix(y1, y2, x * x * (3.0 - 2.0 * x));
}

float curve_sine(float x, float y1, float y2)
{
  float t = (1.0 - cos(x * PI)) / 2.0;
  return mix(y1, y2, t);
}

float curve_exponential(float x, float y1, float y2)
{
  float t = pow(2.0, 10.0 * (x - 1.0));
  return mix(y1, y2, t);
}

float curve_hermite(float x, float y1, float y2, float m1, float m2)
{
  float t2 = x * x;
  float t3 = t2 * x;
  float h1 = 2.0 * t3 - 3.0 * t2 + 1.0;
  float h2 = -2.0 * t3 + 3.0 * t2;
  float h3 = t3 - 2.0 * t2 + x;
  float h4 = t3 - t2;
  return h1 * y1 + h2 * y2 + h3 * m1 + h4 * m2;
}

// =============================================================================

vec2 curve_beizer(float t, vec2 p1, vec2 p2, vec2 p3, vec2 p4)
{
  float t2 = t * t;
  float t3 = t2 * t;
  float mt = 1.0 - t;
  float mt2 = mt * mt;
  float mt3 = mt2 * mt;

  return vec2(
    mt3 * p1.x + 3.0 * mt2 * t * p2.x + 3.0 * mt * t2 * p3.x + t3 * p4.x,
    mt3 * p1.y + 3.0 * mt2 * t * p2.y + 3.0 * mt * t2 * p3.y + t3 * p4.y
  );
}

float curve_interpolate_beizer(float x, vec2 p1, vec2 p2, vec2 p3, vec2 p4)
{
  const int sample_count = 8;
  vec2 samples[sample_count];

  for (int i = 0; i < sample_count; i++) {
    samples[i] = curve_beizer(float(i) / float(sample_count - 1), p1, p2, p3, p4);

    if (samples[i].x > x) {
      if (i == 0) {
        return samples[i].y;
      } else {
        float t = (x - samples[i - 1].x) / (samples[i].x - samples[i - 1].x);
        return curve_linear(t, samples[i - 1].y, samples[i].y);
      }
    }
  }
}

float curve_interpolate_beizer(float x, vec2 p1, vec2 p2)
{
  return curve_interpolate_beizer(x, ZERO2, p1, p2, ONE2);
}

// =============================================================================

float curve_piecewise_linear(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  for (int i = 0; i < point_count - 1; i++) {
    if (x < points[i + 1].x) {
      float t = (x - points[i].x) / (points[i + 1].x - points[i].x);
      return curve_linear(t, points[i].y, points[i + 1].y);
    }
  }
}

float curve_piecewise_cubic(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  for (int i = 0; i < point_count - 1; i++) {
    if (x < points[i + 1].x) {
      float t = (x - points[i].x) / (points[i + 1].x - points[i].x);
      return curve_cubic(t, points[i].y, points[i + 1].y);
    }
  }
}


float curve_piecewise_sine(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  for (int i = 0; i < point_count - 1; i++) {
    if (x < points[i + 1].x) {
      float t = (x - points[i].x) / (points[i + 1].x - points[i].x);
      return curve_sine(t, points[i].y, points[i + 1].y);
    }
  }
}

float curve_piecewise_exponential(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  for (int i = 0; i < point_count - 1; i++) {
    if (x < points[i + 1].x) {
      float t = (x - points[i].x) / (points[i + 1].x - points[i].x);
      return curve_exponential(t, points[i].y, points[i + 1].y);
    }
  }
}

float curve_piecewise_hermite(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  for (int i = 0; i < point_count - 1; i++) {
    if (x < points[i + 1].x) {
      float t = (x - points[i].x) / (points[i + 1].x - points[i].x);
      return curve_hermite(t, points[i].y, points[i + 1].y, points[i].y, points[i + 1].y);
    }
  }
}

// =============================================================================

float curve_interpolate_linear(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  return curve_piecewise_linear(x, points, point_count);
}

float curve_interpolate_cubic(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  for (int i = 0; i < point_count - 1; i++) {
    if (x < points[i + 1].x) {
      float t = (x - points[i].x) / (points[i + 1].x - points[i].x);
      float m1 = (points[i + 1].y - points[i - 1].y) / (points[i + 1].x - points[i - 1].x);
      float m2 = (points[i + 2].y - points[i].y) / (points[i + 2].x - points[i].x);
      return curve_cubic(t, points[i].y, points[i + 1].y);
    }
  }
}

float curve_interpolate_sine(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  for (int i = 0; i < point_count - 1; i++) {
    if (x < points[i + 1].x) {
      float t = (x - points[i].x) / (points[i + 1].x - points[i].x);
      float m1 = (points[i + 1].y - points[i - 1].y) / (points[i + 1].x - points[i - 1].x);
      float m2 = (points[i + 2].y - points[i].y) / (points[i + 2].x - points[i].x);
      return curve_sine(t, points[i].y, points[i + 1].y);
    }
  }
}

float curve_interpolate_hermite(float x, vec4[curve_MAX_POINTS] points, int point_count)
{
  for (int i = 0; i < point_count - 1; i++) {
    if (x < points[i + 1].x) {
      float t = (x - points[i].x) / (points[i + 1].x - points[i].x);
      float m1 = (points[i + 1].y - points[i - 1].y) / (points[i + 1].x - points[i - 1].x);
      float m2 = (points[i + 2].y - points[i].y) / (points[i + 2].x - points[i].x);
      return curve_hermite(t, points[i].y, points[i + 1].y, m1, m2);
    }
  }
}

// =============================================================================

float curve_piecewise_linear(float x, curve_CurvePoints curve_points)
{
  return curve_piecewise_linear(x, curve_points.points, curve_points.point_count);
}

float curve_piecewise_cubic(float x, curve_CurvePoints curve_points)
{
  return curve_piecewise_cubic(x, curve_points.points, curve_points.point_count);
}

float curve_piecewise_sine(float x, curve_CurvePoints curve_points)
{
  return curve_piecewise_sine(x, curve_points.points, curve_points.point_count);
}

float curve_piecewise_exponential(float x, curve_CurvePoints curve_points)
{
  return curve_piecewise_exponential(x, curve_points.points, curve_points.point_count);
}

float curve_piecewise_hermite(float x, curve_CurvePoints curve_points)
{
  return curve_piecewise_hermite(x, curve_points.points, curve_points.point_count);
}

// =============================================================================

float curve_interpolate_linear(float x, curve_CurvePoints curve_points)
{
  return curve_interpolate_linear(x, curve_points.points, curve_points.point_count);
}

float curve_interpolate_cubic(float x, curve_CurvePoints curve_points)
{
  return curve_interpolate_cubic(x, curve_points.points, curve_points.point_count);
}

float curve_interpolate_sine(float x, curve_CurvePoints curve_points)
{
  return curve_interpolate_sine(x, curve_points.points, curve_points.point_count);
}

float curve_interpolate_hermite(float x, curve_CurvePoints curve_points)
{
  return curve_interpolate_hermite(x, curve_points.points, curve_points.point_count);
}

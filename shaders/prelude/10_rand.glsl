/*
 * Random number generator
 * https://www.shadertoy.com/view/Nsf3Ws
 */

// uint _rand_seed = 0u;

// void _rand_hash() {
//     _rand_seed ^= 2747636419u;
//     _rand_seed *= 2654435769u;
//     _rand_seed ^= _rand_seed >> 16;
//     _rand_seed *= 2654435769u;
//     _rand_seed ^= _rand_seed >> 16;
//     _rand_seed *= 2654435769u;
// }

// void rand_init() {
//     _rand_seed = uint(gl_FragCoord.y) * 192u + uint(gl_FragCoord.x) + uint(frame) + uint(time * 10000.0f) * 320u * 192u;
// }

// float rand_rand() {
//     _rand_hash();
//     return float(_rand_seed) / 4294967295.0;
// }

// float rand_range_seeded(float min, float max){
//     return min + rand_rand() * (max - min);
// }

// =============================================================================

// random number generator library (https://www.shadertoy.com/view/ssGXDd)
// by Leonard Ritter (@leonard_ritter)
// license: https://unlicense.org/

// comment out for faster but lower quality hashing
// #define RNGL_HIGH_QUALITY

struct Random { uint s0; uint s1; };

// constructors; note that constructors are wilfully unique,
// i.e. calling a different constructor with the same arguments will not
// necessarily produce the same state.
uint _rand_uhash(uint a, uint b);
Random rand_seed(uint s) { return Random(s, _rand_uhash(0x1ef7c663u, s)); }
Random rand_seed(uvec2 s) { return Random(s.y, _rand_uhash(s.x, s.y)); }
Random rand_seed(Random a, uint b) { return Random(b, _rand_uhash(a.s1, b)); }
Random rand_seed(Random a, uvec2 b) { return rand_seed(a, _rand_uhash(b.x, b.y)); }
Random rand_seed(Random a, uvec3 b) { return rand_seed(a, _rand_uhash(_rand_uhash(b.x, b.y), b.z)); }
Random rand_seed(Random a, uvec4 b) { return rand_seed(a, _rand_uhash(_rand_uhash(b.x, b.y), _rand_uhash(b.z, b.w))); }
Random rand_seed(uvec3 s) { return rand_seed(rand_seed(s.xy), s.z); }
Random rand_seed(uvec4 s) { return rand_seed(rand_seed(s.xy), s.zw); }
Random rand_seed(int s) { return rand_seed(uint(s)); }
Random rand_seed(ivec2 s) { return rand_seed(uvec2(s)); }
Random rand_seed(ivec3 s) { return rand_seed(uvec3(s)); }
Random rand_seed(ivec4 s) { return rand_seed(uvec4(s)); }
Random rand_seed(Random a, int b) { return rand_seed(a, uint(b)); }
Random rand_seed(Random a, ivec2 b) { return rand_seed(a, uvec2(b)); }
Random rand_seed(Random a, ivec3 b) { return rand_seed(a, uvec3(b)); }
Random rand_seed(Random a, ivec4 b) { return rand_seed(a, uvec4(b)); }
Random rand_seed(float s) { return rand_seed(floatBitsToUint(s)); }
Random rand_seed(vec2 s) { return rand_seed(floatBitsToUint(s)); }
Random rand_seed(vec3 s) { return rand_seed(floatBitsToUint(s)); }
Random rand_seed(vec4 s) { return rand_seed(floatBitsToUint(s)); }
Random rand_seed(Random a, float b) { return rand_seed(a, floatBitsToUint(b)); }
Random rand_seed(Random a, vec2 b) { return rand_seed(a, floatBitsToUint(b)); }
Random rand_seed(Random a, vec3 b) { return rand_seed(a, floatBitsToUint(b)); }
Random rand_seed(Random a, vec4 b) { return rand_seed(a, floatBitsToUint(b)); }

// fundamental functions to fetch a new random number
// the last static call to the rng will be optimized out
uint rand_urandom_seeded(inout Random rng) {
    uint last = rng.s1;
    uint next = _rand_uhash(rng.s0, rng.s1);
    rng.s0 = rng.s1; rng.s1 = next;
    return last;
}
uvec2 rand_urandom2_seeded(inout Random rng) { return uvec2(rand_urandom_seeded(rng),rand_urandom_seeded(rng)); }
uvec3 rand_urandom3_seeded(inout Random rng) { return uvec3(rand_urandom2_seeded(rng),rand_urandom_seeded(rng)); }
uvec4 rand_urandom4_seeded(inout Random rng) { return uvec4(rand_urandom2_seeded(rng),rand_urandom2_seeded(rng)); }
int rand_irandom_seeded(inout Random rng) { return int(rand_urandom_seeded(rng)); }
ivec2 rand_irandom2_seeded(inout Random rng) { return ivec2(rand_urandom2_seeded(rng)); }
ivec3 rand_irandom3_seeded(inout Random rng) { return ivec3(rand_urandom3_seeded(rng)); }
ivec4 rand_irandom4_seeded(inout Random rng) { return ivec4(rand_urandom4_seeded(rng)); }

float _rand_unorm(uint n);
float rand_random_seeded(inout Random rng) { return _rand_unorm(rand_urandom_seeded(rng)); }
vec2 rand_random2_seeded(inout Random rng) { return vec2(rand_random_seeded(rng),rand_random_seeded(rng)); }
vec3 rand_random3_seeded(inout Random rng) { return vec3(rand_random2_seeded(rng),rand_random_seeded(rng)); }
vec4 rand_random4_seeded(inout Random rng) { return vec4(rand_random2_seeded(rng),rand_random2_seeded(rng)); }

// ranged random value < maximum value
int rand_range_seeded(inout Random rng, int mn, int mx) { return mn + (rand_irandom_seeded(rng) % (mx - mn)); }
ivec2 rand_range_seeded(inout Random rng, ivec2 mn, ivec2 mx) { return mn + (rand_irandom2_seeded(rng) % (mx - mn)); }
ivec3 rand_range_seeded(inout Random rng, ivec3 mn, ivec3 mx) { return mn + (rand_irandom3_seeded(rng) % (mx - mn)); }
ivec4 rand_range_seeded(inout Random rng, ivec4 mn, ivec4 mx) { return mn + (rand_irandom4_seeded(rng) % (mx - mn)); }
uint rand_range_seeded(inout Random rng, uint mn, uint mx) { return mn + (rand_urandom_seeded(rng) % (mx - mn)); }
uvec2 rand_range_seeded(inout Random rng, uvec2 mn, uvec2 mx) { return mn + (rand_urandom2_seeded(rng) % (mx - mn)); }
uvec3 rand_range_seeded(inout Random rng, uvec3 mn, uvec3 mx) { return mn + (rand_urandom3_seeded(rng) % (mx - mn)); }
uvec4 rand_range_seeded(inout Random rng, uvec4 mn, uvec4 mx) { return mn + (rand_urandom4_seeded(rng) % (mx - mn)); }
float rand_range_seeded(inout Random rng, float mn, float mx) { float x=rand_random_seeded(rng); return mn*(1.0-x) + mx*x; }
vec2 rand_range_seeded(inout Random rng, vec2 mn, vec2 mx) { vec2 x=rand_random2_seeded(rng); return mn*(1.0-x) + mx*x; }
vec3 rand_range_seeded(inout Random rng, vec3 mn, vec3 mx) { vec3 x=rand_random3_seeded(rng); return mn*(1.0-x) + mx*x; }
vec4 rand_range_seeded(inout Random rng, vec4 mn, vec4 mx) { vec4 x=rand_random4_seeded(rng); return mn*(1.0-x) + mx*x; }

// marshalling functions for storage in image buffer and rng replay
vec2 rand_marshal(Random a) { return uintBitsToFloat(uvec2(a.s0,a.s1)); }
Random rand_unmarshal(vec2 a) { uvec2 u = floatBitsToUint(a); return Random(u.x, u.y); }

// specific distributions

// normal/gaussian distribution
// see https://en.wikipedia.org/wiki/Normal_distribution
// float rand_gaussian(inout Random rng, float mu, float sigma) {
//     vec2 q = rand_random2_seeded(rng);
//     float g2rad = sqrt(-2.0 * (log(1.0 - q.y)));
//     float z = cos(q.x*6.28318530718) * g2rad;
//     return mu + z * sigma;
// }

// // triangular distribution
// // see https://en.wikipedia.org/wiki/Triangular_distribution
// // mode is a mixing argument in the range 0..1
// float triangular(inout Random rng, float low, float high, float mode) {
//     float u = rand_random(rng);
//     if (u > mode) {
//         return high + (low - high) * (sqrt ((1.0 - u) * (1.0 - mode)));
//     } else {
//         return low + (high - low) * (sqrt (u * mode));
//     }
// }
// float triangular(inout Random rng, float low, float high) { return triangular(rng, low, high, 0.5); }

// // after https://www.shadertoy.com/view/4t2SDh
// // triangle distribution in the range -0.5 .. 1.5
// float triangle(inout Random rng) {
//     float u = rand_random(rng);
//     float o = u * 2.0 - 1.0;
//     return max(-1.0, o / sqrt(abs(o))) - sign(o) + 0.5;
// }

// //// geometric & euclidean distributions

// // uniformly random point on the edge of a unit circle
// // produces 2d normal vector as well
// vec2 uniform_circle_edge (inout Random rng) {
//     float u = rand_random(rng);
//     float phi = 6.28318530718*u;
//     return vec2(cos(phi),sin(phi));
// }

// // uniformly random point in unit circle
// vec2 uniform_circle_area (inout Random rng) {
//     return uniform_circle_edge(rng)*sqrt(rand_random(rng));
// }

// // gaussian random point in unit circle
// vec2 gaussian_circle_area (inout Random rng, float k) {
//     return uniform_circle_edge(rng)*sqrt(-k*log(rand_random(rng)));
// }
// vec2 gaussian_circle_area (inout Random rng) { return gaussian_circle_area(rng, 0.5); }

// // cartesian coordinates of a uniformly random point within a hexagon
// vec2 uniform_hexagon_area (inout Random rng, float phase) {
//     vec2 u = rand_random2_seeded(rng);
//     float phi = 6.28318530718*u.x;

//     const float sqrt3div4 = sqrt(3.0 / 4.0);
//     const float pidiv6 = 0.5235987755982988;
//     float r = sqrt3div4 / cos(mod(phi + phase, 2.0 * pidiv6) - pidiv6);

//     return vec2(cos(phi), sin(phi)) * r * sqrt(u.y);
// }

// vec2 uniform_hexagon_area (inout Random rng) {
//     return uniform_hexagon_area(rng, 1.5707963267948966);
// }

// // barycentric coordinates of a uniformly random point within a triangle
// vec3 uniform_triangle_area (inout Random rng) {
//     vec2 u = rand_random2_seeded(rng);
//     if (u.x + u.y > 1.0) {
//         u = 1.0 - u;
//     }
//     return vec3(u.x, u.y, 1.0-u.x-u.y);
// }

// // uniformly random on the surface of a sphere
// // produces normal vectors as well
// vec3 uniform_sphere_area (inout Random rng) {
//     vec2 u = rand_random2_seeded(rng);
//     float phi = 6.28318530718*u.x;
//     float rho_c = 2.0 * u.y - 1.0;
//     float rho_s = sqrt(1.0 - (rho_c * rho_c));
//     return vec3(rho_s * cos(phi), rho_s * sin(phi), rho_c);
// }

// // uniformly random within the volume of a sphere
// vec3 uniform_sphere_volume (inout Random rng) {
//     return uniform_sphere_area(rng) * pow(rand_random(rng), 1.0/3.0);
// }

// // barycentric coordinates of a uniformly random point within a 3-simplex
// // based on "Generating Random Points in a Tetrahedron" by Rocchini et al
// vec4 uniform_simplex_volume (inout Random rng) {
//     vec3 u = rand_random3_seeded(rng);
//     if(u.x + u.y > 1.0) {
//         u = 1.0 - u;
//     }
//     if(u.y + u.z > 1.0) {
//         u.yz = vec2(1.0 - u.z, 1.0 - u.x - u.y);
//     } else if(u.x + u.y + u.z > 1.0) {
//         u.xz = vec2(1.0 - u.y - u.z, u.x + u.y + u.z - 1.0);
//     }
//     return vec4(1.0 - u.x - u.y - u.z, u);
// }

// // for differential evolution, in addition to index K, we need to draw three more
// // indices a,b,c for a list of N items, without any collisions between k,a,b,c.
// // this is the O(1) hardcoded fisher-yates shuffle for this situation.
// ivec3 sample_k_3(inout Random rng, int N, int K) {
//     ivec3 t = rand_range_seeded(rng, ivec3(1,2,3), ivec3(N));
//     int db = (t.y == t.x)?1:t.y;
//     int dc = (t.z == t.y)?((t.x != 2)?2:1):((t.z == t.x)?1:t.z);
//     return (K + ivec3(t.x, db, dc)) % N;
// }

/////////////////////////////////////////////////////////////////////////

// auxiliary functions from http://extremelearning.com.au/unreasonable-effectiveness-of-quasrand_irandom-sequences/
// The Unreasonable Effectiveness of Quasrand_irandom Sequences, by Martin Roberts
float rand_r1(float o, int i) {
    return fract(o + float(i * 10368889)/exp2(24.0));
}
vec2 rand_r2(vec2 o, int i) {
    return fract(o + vec2(i * ivec2(12664745, 9560333))/exp2(24.0));
}
vec3 rand_r3(vec3 o, int i) {
    return fract(o + vec3(i * ivec3(13743434, 11258243, 9222443))/exp2(24.0));
}
vec4 rand_r4(vec4 o, int i) {
    return fract(o + vec4(i * ivec4(14372619, 12312662, 10547948, 9036162))/exp2(24.0));
}

float rand_r1(int i) { return rand_r1(0.5, i); }
vec2 rand_r2(int i) { return rand_r2(vec2(0.5), i); }
vec3 rand_r3(int i) { return rand_r3(vec3(0.5), i); }
vec4 rand_r4(int i) { return rand_r4(vec4(0.5), i); }

/////////////////////////////////////////////////////////////////////////

// if it turns out that you are unhappy with the distribution or performance
// it is possible to exchange this function without changing the interface
uint _rand_uhash(uint a, uint b) {
    uint x = ((a * 1597334673U) ^ (b * 3812015801U));
#ifdef RNGL_HIGH_QUALITY
    // from https://nullprogram.com/blog/2018/07/31/
    x = x ^ (x >> 16u);
    x = x * 0x7feb352du;
    x = x ^ (x >> 15u);
    x = x * 0x846ca68bu;
    x = x ^ (x >> 16u);
#else
    x = x * 0x7feb352du;
    x = x ^ (x >> 15u);
    x = x * 0x846ca68bu;
#endif
    return x;
}

float _rand_unorm(uint n) { return float(n) * (1.0 / float(0xffffffffU)); }

// =============================================================================

Random rand_rng = Random(0u, 0u);
Random rand_rng_uv = Random(0u, 0u);

float rand_random() { return rand_random_seeded(rand_rng); }
vec2 rand_random2() { return rand_random2_seeded(rand_rng); }
vec3 rand_random3() { return rand_random3_seeded(rand_rng); }
vec4 rand_random4() { return rand_random4_seeded(rand_rng); }

int rand_range(int mn, int mx) { return rand_range_seeded(rand_rng, mn, mx); }
ivec2 rand_range(ivec2 mn, ivec2 mx) { return rand_range_seeded(rand_rng, mn, mx); }
ivec3 rand_range(ivec3 mn, ivec3 mx) { return rand_range_seeded(rand_rng, mn, mx); }
ivec4 rand_range(ivec4 mn, ivec4 mx) { return rand_range_seeded(rand_rng, mn, mx); }
uint rand_range(uint mn, uint mx) { return rand_range_seeded(rand_rng, mn, mx); }
uvec2 rand_range(uvec2 mn, uvec2 mx) { return rand_range_seeded(rand_rng, mn, mx); }
uvec3 rand_range(uvec3 mn, uvec3 mx) { return rand_range_seeded(rand_rng, mn, mx); }
uvec4 rand_range(uvec4 mn, uvec4 mx) { return rand_range_seeded(rand_rng, mn, mx); }
float rand_range(float mn, float mx) { return rand_range_seeded(rand_rng, mn, mx); }
vec2 rand_range(vec2 mn, vec2 mx) { return rand_range_seeded(rand_rng, mn, mx); }
vec3 rand_range(vec3 mn, vec3 mx) { return rand_range_seeded(rand_rng, mn, mx); }
vec4 rand_range(vec4 mn, vec4 mx) { return rand_range_seeded(rand_rng, mn, mx); }

void rand_init() {
    rand_rng = rand_seed(rand_seed(uv), frame);
    rand_rng_uv = rand_seed(uv);
}

const int SEARCH_RADIUS = 5;
const int SEARCH_DIAMETER = 2 * SEARCH_RADIUS + 1;

const float SEARCH_RADIUS_F = float(SEARCH_RADIUS);
const float SEARCH_DIAMETER_F = float(SEARCH_DIAMETER);

float val;
float n;

vec4 read(int x, int y) {
    return read_wrapped_coord(buffGrid, coord + vec2(x, y));
}

vec4 grow() {
    float lval = read(0, 0).x;

    float range_mul = sin(time * (1.0 / 60.0) * 2.0 * 3.14159);
    range_mul = 1.0 + range_mul * 0.01;

    // higher values here induce more smoothing and like more spirals
    // there needs to be a gap between the value below though.
    // kind of like a "contrast" value????
    if (lval > rand_range(0.3, 0.5) * range_mul) {
        float val = lval * (1.0 - rand_range(0.1, 0.2) * 0.0025 * 5.0);
        return vec4(val);
    }

    float val = lval;
    float n = 0.001;

    for (int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++) {
        for (int j = -SEARCH_RADIUS; j <= SEARCH_RADIUS; j++) {
            if (i == 0 && j == 0) {
                continue;
            }

            float lvn = read(j, i).x;

            float ni = float(i) / SEARCH_RADIUS_F;
            float nj = float(j) / SEARCH_RADIUS_F;

            // float weight = 1.0 - ni * ni - nj * nj;
            // float weight = 1.0 - sqrt(ni * ni + nj * nj);
            float weight = SEARCH_DIAMETER_F - sqrt(ni * ni + nj * nj); // wtf
            // weight = clamp(weight, 0.0, 1.0);

            // weight = weight * step(rand_range(0.4, 0.6), lvn);

            // higher values here mean smoother growth, kind of like zooming in
            weight = weight * step(rand_range(0.6, 0.7) * range_mul, lvn);

            // having a higher weight randomization here seems to make things worse?
            // like it decays quicker
            val += lvn * rand_range(1.0, 1.0) * weight;
            n += weight;
        }
    }

    val = val / n;
    val = clamp(val, 0.0, 1.0);

    return vec4(val);
}

vec4 init() {
    float x = rand_rand();
    return vec4(x);
}

vec4 render()
{
    if (time < 0.01) {
        return init();
    } else {
        return grow();
    }
}

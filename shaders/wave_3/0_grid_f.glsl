const int SEARCH_RADIUS = 3;
const int SEARCH_DIAMETER = 2 * SEARCH_RADIUS + 1;

const float SEARCH_RADIUS_F = float(SEARCH_RADIUS);
const float SEARCH_DIAMETER_F = float(SEARCH_DIAMETER);

float val;
float n;

float read(int x, int y) {
    return read_wrapped_coord(buff0, coord + vec2(x, y)).x;
}

float grow() {
    float lval = read(0, 0);
    float val = lval * (1.0 - rand_range(0.1, 0.2) * timeDelta * 0.15);

    float range_mul = sin(time * (1.0 / 60.0) * PI2);
    range_mul = 1.0 + range_mul * 0.1;

    // higher values here induce more smoothing and like more spirals
    // there needs to be a gap between the value below though.
    // kind of like a "contrast" value????
    if (val > rand_range(0.3, 0.4) * range_mul) {
        return float(val);
    }

    float n = 0.0;

    for (int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++) {
        for (int j = -SEARCH_RADIUS; j <= SEARCH_RADIUS; j++) {
            if (i == 0 && j == 0) {
                continue;
            }

            float lvn = read(j, i);

            float ni = float(i) / SEARCH_RADIUS_F;
            float nj = float(j) / SEARCH_RADIUS_F;

            // float weight = 1.0 - ni * ni - nj * nj; // bugged, sharp corners (og)
            // float weight = 1.0 - sqrt(ni * ni + nj * nj); // needs large radius
            // float weight = SEARCH_DIAMETER_F - sqrt(ni * ni + nj * nj); // wtf
            float weight = SEARCH_DIAMETER_F - sqrt(ni * ni + nj * nj) * (SEARCH_RADIUS_F - 1.0); // wtf but bigger spirals!?
            // float weight = 1.0; // functionally the same as the one above, i think

            // higher values here mean smoother growth, kind of like zooming in
            // randomness here is very important to keep it alive
            weight = weight * smoothstep(rand_range(0.5, 0.65) * range_mul, 0.7 * range_mul, lvn);

            // having a higher weight randomization here seems to make things worse?
            // like it decays quicker
            val += lvn * rand_range(0.95, 1.05) * weight;
            n += weight;
        }
    }

    val = val / n;
    val = clamp(val, 0.0, 1.0);

    return val;
}

float init() {
    float x = rand_rand();
    return x;
}

vec4 render()
{
    float o = 0.0;

    if (time < 0.01) {
        o = init();
    } else {
        o = grow();
    }

    return vec4(vec3(o), 1.0);
}

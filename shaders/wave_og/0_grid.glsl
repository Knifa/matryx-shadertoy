const int SEARCH_RADIUS = 2;
// const int SEARCH_RADIUS = 2;
const int SEARCH_DIAMETER = 2 * SEARCH_RADIUS + 1;

const float SEARCH_RADIUS_F = float(SEARCH_RADIUS);
const float SEARCH_DIAMETER_F = float(SEARCH_DIAMETER);

vec4 read(int x, int y) {
    return read_wrapped_coord(buffGrid, coord + vec2(x, y));
}

vec4 grow() {
    float lval = read(0, 0).x;

    // if (lval > rand_range(0.2, 0.3)) {
    if (lval > rand_range(0.1, 0.35)) {
        float val = lval * (1.0 - rand_range(0.2, 0.4) * timeDelta);
        return vec4(val);
    }

    float c = 0.0;
    float n = 0.0;

    for (int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++) {
        for (int j = -SEARCH_RADIUS; j <= SEARCH_RADIUS; j++) {
            if (i == 0 && j == 0) {
                continue;
            }

            float lvn = read(i, j).x;
            if (lvn <= rand_range(0.4, 0.6)) {
                continue;
            }

            float dist = float(i * i + j * j);
            // float weight = pow(1.0 / dist, 2.0);
            float weight = pow(1.0 / dist, 0.5);

            // c += lvn * rand_range(1.0, 1.0) * weight;
            c += lvn * rand_range(0.9, 1.1) * weight;
            n += weight;
        }
    }

    float val = (lval + c) / n;
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

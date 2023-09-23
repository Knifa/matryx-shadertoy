vec4 init() {
    float x = rand_rand();

    // if (uv.x > 0.4 && uv.x < 0.6 && uv.y > 0.4 && uv.y < 0.6) {
    //     return vec4(1.0, 1.0, 1.0, 1.0);
    // } else {
    //     return vec4(0.0, 0.0, 0.0, 1.0);
    // }

    // if (coord.x >= resolution.x / 2.0 - 1.0 && coord.x <= resolution.x / 2.0 + 1.0 &&
    //     coord.y >= resolution.y / 2.0 - 1.0 && coord.y <= resolution.y / 2.0 + 1.0) {
    //     return vec4(1.0, 1.0, 1.0, 1.0);
    // } else {
    //     return vec4(0.0, 0.0, 0.0, 1.0);
    // }

    // vec2 centerCoord = vec2(resolution.x / 2.0, resolution.y / 2.0);
    // vec2 distanceFrom = gl_FragCoord.xy - centerCoord;

    // if (length(distanceFrom) < 32.0) {
    //     return vec4(1.0, 1.0, 1.0, 1.0);
    // } else {
    //     return vec4(0.0, 0.0, 0.0, 1.0);
    // }

    return vec4(x, x, x, 1.0);
}

vec4 grow() {
    vec4 lval = texelFetch(buffGrid, ivec2(gl_FragCoord.xy), 0);
    vec4 val = lval * (1.0 - rand_range(0.1, 0.2) * timeDelta * 1.0);

    if (val.x > rand_range(0.1, 0.35)) {
        return vec4(val.xyz, 1.0);
    }

    vec4 thresVal = texelFetch(buffThresh, ivec2(gl_FragCoord.xy), 0);
    vec4 neighVal = texelFetch(buffNeigh, ivec2(gl_FragCoord.xy), 0);
    vec4 weightVal = texelFetch(buffWeights, ivec2(gl_FragCoord.xy), 0);

    val = neighVal;
    val = val / weightVal;

    // float n = 0.0;

    // for (int i = -SEARCH_RADIUS; i <= SEARCH_RADIUS; i++) {
    //     for (int j = -SEARCH_RADIUS; j <= SEARCH_RADIUS; j++) {
    //         vec4 lval2 = texelFetch(buffGrid, ivec2(gl_FragCoord.xy) + ivec2(i, j), 0);

    //         if (lval2.x >= rand_range(0.4, 0.6)) {
    //         // if (lval2.x >= THRESH) {
    //             float nx = float(i) / (float(SEARCH_RADIUS) * 2.0);
    //             float ny = float(j) / (float(SEARCH_RADIUS) * 2.0);
    //             float weight = 1.0 - clamp(length(vec2(nx, ny)), 0.0, 1.0);
    //             // weight = clamp(weight, 0.0, 1.0);
    //             // weight = pow(weight, 2.0);

    //             val += lval2 * weight;
    //             n += weight;
    //         }
    //     }
    // }

    // val = val / n;

    val = clamp(val, 0.0, 1.0);
    return vec4(val.xyz, 1.0);
}

vec4 render()
{
    if (time < 0.01) {
        return init();
    } else {
        return grow();
    }
}

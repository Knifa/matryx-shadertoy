/*
 * Random number generator
 * https://www.shadertoy.com/view/Nsf3Ws
 */

uint _rand_seed = 0u;

void _rand_hash() {
    _rand_seed ^= 2747636419u;
    _rand_seed *= 2654435769u;
    _rand_seed ^= _rand_seed >> 16;
    _rand_seed *= 2654435769u;
    _rand_seed ^= _rand_seed >> 16;
    _rand_seed *= 2654435769u;
}

void rand_init() {
    _rand_seed = uint(gl_FragCoord.y) * 192u + uint(gl_FragCoord.x) + uint(frame) + uint(time * 10000.0f) * 320u * 192u;
}

float rand_rand() {
    _rand_hash();
    return float(_rand_seed) / 4294967295.0;
}

float rand_range(float min, float max){
    return min + rand_rand() * (max - min);
}

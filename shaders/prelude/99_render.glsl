vec4 render();

void main() {
    coord = gl_FragCoord.xy;

    uv = coord2uv(coord);
    uv_asp = uv * resolution_aspect;

    uv_centered = uv - 0.5;
    uv_centered_asp = uv_centered * resolution_aspect;

    rand_init();

    fragColor = render();
    fragColor2 = fragColor;
}

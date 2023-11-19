vec4 render()
{
    float outside;


    float e, q;

    e = abs(uv_centered.y);
    e = smoothstep(0.0, 3.0, e) * 1.0 + 0.018;

    q = sign(uv_centered.y) * e;
    q = pow(q, 2.0);

    outside = (
        sin((uv_centered.x / q) * PI2 * 0.0025 + time_tan(10.0))
        * cos((uv_centered.x + uv_centered.y) * PI2 * 2.25 + time_tan(30.0))
    );

    outside = norm(outside, -1.0, 1.0);
    outside = smoothstep(0.45, 0.8, outside);

    return vec4(
        outside,
        outside,
        outside,
        1.0
    );
}

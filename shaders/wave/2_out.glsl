vec4 getTexColor(sampler2D tex, vec2 uv)
{
    vec4 c = texture(tex, uv);
    return c;
}

vec4 niceifyColor(vec4 c)
{
    c = pow(c, vec4(4.0, 3.0, 2.0, 1.0));
    c = clamp(c, vec4(0.0), vec4(1.0));

    return c;
}

vec4 outAtUv(vec2 uv)
{
    vec4 c = getTexColor(buff0, uv) * 0.0 + getTexColor(buff1, uv) * 1.0;
    c = niceifyColor(c);

    return c;
}

void main()
{
    fragColor = outAtUv(gl_FragCoord.xy / vec2(320, 192));

    vec4 bloom = vec4(0.0);

    for (int x = -4; x <= 4; x++)
    for (int y = -4; y <= 4; y++)
    {
        float weight = 1.0 / (abs(float(x)) + abs(float(y)) + 1.0);
        weight = pow(weight, 2.0);

        vec4 texColor = outAtUv(
            (gl_FragCoord.xy + vec2(float(x), float(y))) / vec2(320, 192)
        );

        bloom += texColor * weight;
    }

    fragColor += bloom * 1.0;

    float x = gl_FragCoord.x;
    float y = gl_FragCoord.y;
    float t = time;

    float xp = ((x / 128.0) - 0.5) * (5.0 + sin(t * 0.25)) + sin(t * 0.25) * 5.0;
    float yp = ((y / 128.0) - 0.5) * (5.0 + sin(t * 0.25)) + cos(t * 0.25) * 5.0;

    float pixel = (sin(0.25 * t) * xp + cos(0.29 * t) * yp + t)
                + (sqrt(pow(xp + sin(t * 0.25) * 4.0, 2.0) + pow(yp + cos(t * 0.43) * 4.0, 2.0)) + t)
                - (sqrt(pow(xp + cos(t * 0.36) * 6.0, 2.0) + pow(yp + sin(t * 0.39) * 5.3, 2.0)) + t);

    // float u = pow((((9.0 * pixel + 0.5 * xp + t) * cos(0.5) / 2.0) + 0.5), 2.0);
    // float v = pow((((9.0 * pixel + 0.5 * yp + t) * sin(0.5) / 2.0) + 0.5), 2.0);

    pixel = sin(pixel);

    float u = (sin(xp * 0.1 * pixel + t) / 2.0) + 0.5;
    float v = (sin(yp * 0.2 * pixel + t) / 2.0) + 0.5;

    fragColor = fragColor * (0.1 + (vec4(u, v, (u + v) / 2.0, 1.0)) * 0.9);
};




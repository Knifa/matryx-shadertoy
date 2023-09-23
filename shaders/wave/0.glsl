void main()
{
    vec2 uv = gl_FragCoord.xy / vec2(320.0, 192.0);

    if (time < 0.1) {
        float x = 0.0;
        x = sin(gl_FragCoord.x * gl_FragCoord.y * cos(gl_FragCoord.x * gl_FragCoord.y));

        fragColor = vec4(x, x, x, 1.0);
    } else {
        float l = texture(buff1, uv).r;
        float v = 0.0;

        if (l <= 0.1) {
           float n = 0.0;

            for (int i = -4; i <= 4; i++) {
                for (int j = -4; j <= 4; j++) {
                    if (i == 0 && j == 0) {
                        //continue;
                    }

                    vec2 uv2 = vec2(gl_FragCoord.x + float(i), gl_FragCoord.y + float(j)) / vec2(320.0, 192.0);
                    float l2 = texture(buff1, uv2).r;
                    if (l2 >= 0.6) {
                        float w = pow(float(i), 2.0) + pow(float(j), 2.0);
                        w = clamp(pow(1.0 / w, 1.0), 0.0, 1.0);

                        v += l2 * w;
                        n += w;
                    }
                }
            }

            if (n <= 0.01) {
                v = pow(l, 0.5);
            } else {
                v = (l + v) / (n);
            }

            v = clamp(v, 0.0, 1.0);
        } else {
            v = l - (l * timeDelta * 0.25);
        }

        fragColor = vec4(v, v, v, 1.0);
    }
};

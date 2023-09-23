vec4 getTexColor(sampler2D tex, vec2 uv)
{
    vec4 c = texture(tex, uv);
    return c;
}

void main()
{
    vec4 lastFragColor = getTexColor(buff1, gl_FragCoord.xy / vec2(320, 192));
    vec4 nextFragColor = getTexColor(buff0, gl_FragCoord.xy / vec2(320, 192));
    nextFragColor = pow(nextFragColor, vec4(2.0));

    vec4 c = mix(lastFragColor, nextFragColor, timeDelta * 2.0);

    fragColor = c;
};



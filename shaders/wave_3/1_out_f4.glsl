// Define kernels
#define identity mat3(0, 0, 0, 0, 1, 0, 0, 0, 0)
#define edge0 mat3(1, 0, -1, 0, 0, 0, -1, 0, 1)
#define edge1 mat3(0, 1, 0, 1, -4, 1, 0, 1, 0)
#define edge2 mat3(-1, -1, -1, -1, 8, -1, -1, -1, -1)
#define sharpen mat3( \
     0, -1,  0, \
    -1,  5, -1, \
     0, -1,  0)
#define box_blur mat3(1, 1, 1, 1, 1, 1, 1, 1, 1) * 0.1111
#define gaussian_blur mat3(1, 2, 1, 2, 4, 2, 1, 2, 1) * 0.0625
#define emboss mat3(-2, -1, 0, -1, 1, 1, 0, 1, 2)

// Find coordinate of matrix element from index
vec2 kpos(int index)
{
    return vec2[9] (
        vec2(-1, -1), vec2(0, -1), vec2(1, -1),
        vec2(-1, 0), vec2(0, 0), vec2(1, 0),
        vec2(-1, 1), vec2(0, 1), vec2(1, 1)
    )[index];
}


// Extract region of dimension 3x3 from sampler centered in uv
// sampler : texture sampler
// uv : current coordinates on sampler
// return : an array of mat3, each index corresponding with a color channel
mat3[3] region3x3(sampler2D sampler, vec2 uv)
{
    // Create each pixels for region
    vec4[9] region;

    for (int i = 0; i < 9; i++) {
        region[i] = read_coord_wrap(sampler, uv + kpos(i));

        // Some bullshit here to make it Nice.
        region[i] = pow(region[i], vec4(1.25));
    }

    // Create 3x3 region with 3 color channels (red, green, blue)
    mat3[3] mRegion;

    for (int i = 0; i < 3; i++) {
        mRegion[i] = mat3(
        	region[0][i], region[1][i], region[2][i],
        	region[3][i], region[4][i], region[5][i],
        	region[6][i], region[7][i], region[8][i]
    	);
    }

    return mRegion;
}

// Convolve a texture with kernel
// kernel : kernel used for convolution
// sampler : texture sampler
// uv : current coordinates on sampler
vec3 convolution(mat3 kernel, sampler2D sampler, vec2 uv)
{
    vec3 fragment;

    // Extract a 3x3 region centered in uv
    mat3[3] region = region3x3(sampler, uv);

    // for each color channel of region
    for (int i = 0; i < 3; i++)
    {
        // get region channel
        mat3 rc = region[i];
        // component wise multiplication of kernel by region channel
        mat3 c = matrixCompMult(kernel, rc);
        // add each component of matrix
        float r = c[0][0] + c[1][0] + c[2][0]
                + c[0][1] + c[1][1] + c[2][1]
                + c[0][2] + c[1][2] + c[2][2];

        // for fragment at channel i, set result
        fragment[i] = r;
    }

    return fragment;
}


vec4 render()
{
    float x = mix(
        convolution(sharpen, buffPrev, vec2(gl_FragCoord.xy)).x,
        convolution(gaussian_blur, buffPrev, vec2(gl_FragCoord.xy)).x,
    0.75);

    x = clamp(x, 0.0, 1.0);
    // x = smoothstep(0.0, 1.0, x);

    float lx = pow(x, 1.1);
    float l = remap(
        lx,
        0.0, 1.0,
        0.0, 1.0
    );

    float cx = pow(x, 1.0);
    // cx = 1.0 - cx;
    // cx = 1.0 - abs((1.0 - cx) - 0.5) * 2.0;
    float c = remap(
        cx,
        0.0, 1.0,
        0.0, 0.25
    );

    float h = pow(x, 1.0) * 270.0;

    h +=
        (
            sin(uv_centered_asp.x * (PI / 3.0) + (time * 1.0 / 55.0))
            + cos(uv_centered_asp.y * (PI / 4.0) + (time * 1.0 / 65.0))
        ) * 90.0;
    h += uv_centered.x * 15.0 + uv_centered.y * 15.0;
    h += (time * 1.0 / 60.0) * 360.0;
    h = mod(h, 360.0);

    c *= remap(
        (
            cos(uv_centered_asp.x * (PI / 2.35) + (time * 1.0 / 45.0))
            + sin(uv_centered_asp.y * (PI / 4.6) + (time * 1.0 / 47.5))
            * cos(uv_centered_asp.x * (PI / 2.5) + (time * 1.0 / 69.0))
        ), -2.0, 2.0, 0.5, 1.0);

    return vec4(OKLCH_TO_SRGB(vec3(l, c, h)), 1.0);
    // return vec4(OKLCH_TO_SRGB(vec3(1.0 - l, c, h)), 1.0);
    // return vec4(OKLCH_TO_SRGB(vec3(l, 0.3 - c, h)), 1.0);
    // return vec4(OKLCH_TO_SRGB(vec3(1.0 - l, 0.3 - c, h)), 1.0);

    // ==== DEBUG ====
    // return vec4(OKLCH_TO_SRGB(vec3(1.0, 0.5, h)), 1.0);
    // return vec4(LCH_TO_SRGB(vec3(50.0, 50.0, h)), 1.0);
    // return vec4(h / 360.0, h / 360.0, h / 360.0, 1.0);
    // return vec4(uv.x, 0.0, 0.0, 1.0);

    // return vec4(LAB_TO_SRGB(
    //     vec3(
    //         75.0,
    //         cos(uv_centered_asp.x * PI + time) * (1.0 - l) * 100.0,
    //         sin(uv_centered_asp.y * PI + time) * (1.0 - l) * 100.0
    //     )
    // ), 1.0);
    // return vec4(LAB_TO_SRGB(vec3(l * 75.0, uv_centered_asp.x * 100.0, uv_centered_asp.y * 100.0)), 1.0);
};

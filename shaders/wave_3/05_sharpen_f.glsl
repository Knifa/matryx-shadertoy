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
        region[i] = pow(region[i], vec4(0.9));
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

vec4 render() {
  float x = mix(
      convolution(sharpen, buffPrev, coord).x,
      convolution(gaussian_blur, buffPrev, coord).x,
  0.8);

  return vec4(x, x, x, 1.0);
}

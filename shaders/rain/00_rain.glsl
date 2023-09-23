vec4 render()
{
  // Fixed seed for reproducibility
  _rand_seed = uint(gl_FragCoord.y + sin(time) * 10.0) * 192u * uint(gl_FragCoord.x + time * 200.0) * 320u;

  return vec4(
    step(0.9995, rand_rand())
  );
}

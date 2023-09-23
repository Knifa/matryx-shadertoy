#define buffThresh buff0
#define buffNeigh buff2
#define buffWeights buff4
#define buffGrid buff5

#define buffOut buffGrid

const int SEARCH_RADIUS = 11;
const int SEARCH_DIAMETER = 2 * SEARCH_RADIUS + 1;

const float THRESH = 0.4;

float get_weight(float dist) {
  return 1.0f - (dist * dist * 1.41421356237f);
}

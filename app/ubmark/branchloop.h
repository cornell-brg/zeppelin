//========================================================================
// branchloop.h
//========================================================================
// Test data for the branch-misprediction microbenchmark.
//
// 128 pseudo-random integers in [0, 1023]. Two thresholds (341, 682)
// split data into three bins. Branchless and branchy versions both
// compute the same bin counts.

#ifndef APP_UBMARK_BRANCHLOOP_H
#define APP_UBMARK_BRANCHLOOP_H

const int eval_size = 128;
const int eval_thresh_lo = 341;
const int eval_thresh_hi = 682;

int eval_data[128] = {
  734, 158, 891,  47, 523, 276, 965, 412, 189, 650, 803,  34, 571, 917, 102, 468,
  345, 729, 256,  88, 614, 993, 167, 445, 778, 321,  55, 899, 532, 210, 686, 143,
  867, 401,  19, 752, 594, 128, 483, 936, 271, 660, 815,  76, 547, 389, 712, 234,
  958,  92, 505, 173, 841, 637, 310,  63, 426, 789, 154, 968, 281, 542, 695, 118,
  853, 207, 470, 734,  25, 596, 361, 919, 148, 683, 506,  81, 264, 937, 422, 758,
  190, 845, 573, 317,  49, 701, 438, 162, 924, 655, 286,  13, 548, 831, 107, 479,
  763, 225, 892, 370, 641, 514,  98, 186, 729, 457,  33, 815, 562, 291, 678, 143,
  906, 348, 127, 783, 471, 239, 954, 616,  67, 502, 855, 178, 714, 393,  41, 580
};

// Precomputed bin counts:
// bin_lo (data[i] < 341):  48 elements
// bin_mid (341 <= data[i] < 682): 41 elements
// bin_hi (data[i] >= 682):  39 elements
const int eval_ref_lo  = 48;
const int eval_ref_mid = 41;
const int eval_ref_hi  = 39;

#endif // APP_UBMARK_BRANCHLOOP_H

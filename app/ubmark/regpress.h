//========================================================================
// regpress.h
//========================================================================
// Test data for the register-pressure microbenchmark.
//
// 128 integers. Low-pressure uses 4 accumulators, high-pressure uses 16.
// Both accumulate with different operations to exercise ALU pipes.

#ifndef APP_UBMARK_REGPRESS_H
#define APP_UBMARK_REGPRESS_H

const int eval_size = 128;

int eval_data[128] = {
   7, 13, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73,
  79, 83, 89, 97,  3, 11, 17, 23, 29, 37, 41, 43, 47, 53, 59, 61,
  67, 71, 73, 79, 83, 89, 97,  3,  7, 11, 13, 17, 19, 23, 29, 31,
  37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,  3,  7,
  11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
  73, 79, 83, 89, 97,  3,  7, 11, 13, 17, 19, 23, 29, 31, 37, 41,
  43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97,  3,  7, 11, 13,
  17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79
};

// Reference for low-pressure (4 accumulators):
//   a0 += data[i],  a1 ^= data[i],  a2 += data[i]*data[i],  a3 -= data[i]
const int eval_ref_lo_a0 = 5948;
const int eval_ref_lo_a1 = 116;
const int eval_ref_lo_a2 = 368424;
const int eval_ref_lo_a3 = -5948;

// Reference for high-pressure (16 accumulators):
// a0-a7 and a8-a15 compute the same operations (a8-a15 mirror a0-a7)
const int eval_ref_hi_a0  = 5948;
const int eval_ref_hi_a1  = 116;
const int eval_ref_hi_a2  = 368424;
const int eval_ref_hi_a3  = -5948;
const int eval_ref_hi_a4  = 11896;
const int eval_ref_hi_a5  = 68;
const int eval_ref_hi_a6  = 6588;
const int eval_ref_hi_a7  = -2910;

#endif // APP_UBMARK_REGPRESS_H

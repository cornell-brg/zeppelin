//========================================================================
// mulchain.h
//========================================================================
// Test data for the multiply-chain microbenchmark.
//
// Evaluates a degree-7 polynomial via Horner's method on 64 data points.
// Uses small values to keep results within 32-bit signed integer range.
//
// Polynomial: c[0] + c[1]*x + c[2]*x^2 + ... + c[7]*x^7
// Horner form: c[0] + x*(c[1] + x*(c[2] + ... + x*c[7]))
//
// Coefficients A: {3, -2, 1, 5, -3, 2, -1, 4}
// Coefficients B: {1, 4, -2, 3, 1, -5, 2, -3}
// x-values: 0..7, repeated 8 times (small to avoid overflow)

#ifndef APP_UBMARK_MULCHAIN_H
#define APP_UBMARK_MULCHAIN_H

const int eval_size = 64;
const int eval_degree = 8;

int eval_coeff_a[8] = { 3, -2, 1, 5, -3, 2, -1, 4 };
int eval_coeff_b[8] = { 1, 4, -2, 3, 1, -5, 2, -3 };

int eval_x[64] = {
  0, 1, 2, 3, 4, 5, 6, 7,
  0, 1, 2, 3, 4, 5, 6, 7,
  0, 1, 2, 3, 4, 5, 6, 7,
  0, 1, 2, 3, 4, 5, 6, 7,
  0, 1, 2, 3, 4, 5, 6, 7,
  0, 1, 2, 3, 4, 5, 6, 7,
  0, 1, 2, 3, 4, 5, 6, 7,
  0, 1, 2, 3, 4, 5, 6, 7
};

// Precomputed: sum of poly_a(x) for all 64 x-values
// 8 repetitions of x=0..7
const int eval_ref_a = 37315296;

// Precomputed: sum of poly_b(x) for all 64 x-values
// 8 repetitions of x=0..7
const int eval_ref_b = -26955552;

#endif // APP_UBMARK_MULCHAIN_H

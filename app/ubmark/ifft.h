//========================================================================
// ifft.h
//========================================================================
// Test data for the fixed-point inverse FFT benchmark.
//
// N=32 complex values in Q10 fixed-point (scale factor 1024).
// Precomputed cosine/sine twiddle tables and reference output.
// Input has conjugate symmetry so the time-domain output is real-valued.

#ifndef APP_UBMARK_IFFT_H
#define APP_UBMARK_IFFT_H

const int eval_fft_n     = 32;
const int eval_fft_log2n = 5;
const int eval_fft_scale = 1024;

int eval_cos_tbl[32] = {
   1024,  1004,   946,   851,   724,   569,   392,   200,
      0,  -200,  -392,  -569,  -724,  -851,  -946, -1004,
  -1024, -1004,  -946,  -851,  -724,  -569,  -392,  -200,
      0,   200,   392,   569,   724,   851,   946,  1004
};

int eval_sin_tbl[32] = {
      0,   200,   392,   569,   724,   851,   946,  1004,
   1024,  1004,   946,   851,   724,   569,   392,   200,
      0,  -200,  -392,  -569,  -724,  -851,  -946, -1004,
  -1024, -1004,  -946,  -851,  -724,  -569,  -392,  -200
};

// Frequency-domain input (conjugate symmetric => real output)
int eval_in_real[32] = {
    51200,   20480,   10240,       0,   -5120,       0,       0,       0,
     8192,       0,       0,       0,       0,       0,       0,       0,
        0,       0,       0,       0,       0,       0,       0,       0,
     8192,       0,       0,       0,   -5120,       0,   10240,   20480
};

int eval_in_imag[32] = {
        0,  -10240,    5120,       0,   15360,       0,       0,       0,
    -3072,       0,       0,       0,       0,       0,       0,       0,
        0,       0,       0,       0,       0,       0,       0,       0,
     3072,       0,       0,       0,  -15360,       0,   -5120,   10240
};

// Reference IDFT output (real part; imaginary part is all zeros)
int eval_ref_real[32] = {
     3712,    2735,    1781,    2324,    3469,    3399,    2450,    2024,
     1792,     795,       3,     826,    2299,    2529,    1789,    1444,
     1152,     -24,   -1073,    -514,     754,     913,     288,     269,
      512,      40,    -199,    1185,    3204,    3945,    3664,    3704
};

int eval_ref_imag[32] = {
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0
};

#endif // APP_UBMARK_IFFT_H

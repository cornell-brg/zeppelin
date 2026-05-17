//========================================================================
// ifft-naive.cpp
//========================================================================
// Fixed-point inverse FFT benchmark: naive IDFT variant.
//
// For each of the 32 output samples, sum over all 32 input bins
// multiplied by the appropriate twiddle factor.  This is O(N^2) work,
// but each output point's sum is fully independent, giving the
// out-of-order engine many overlapping multiply-add chains to exploit.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "ifft.h"

//----------------------------------------------------------------------
// Helpers
//----------------------------------------------------------------------

static int abs_val( int x ) { return x < 0 ? -x : x; }

//----------------------------------------------------------------------
// naive_idft -- O(N^2), high ILP
//----------------------------------------------------------------------

__attribute__((noinline))
void naive_idft( int* out_real, int* out_imag,
                 int* in_real, int* in_imag,
                 int* cos_tbl, int* sin_tbl, int n )
{
  for ( int i = 0; i < n; i++ ) {
    long long sum_r = 0, sum_i = 0;
    for ( int k = 0; k < n; k++ ) {
      int idx = (i * k) % n;
      int c = cos_tbl[idx];
      int s = sin_tbl[idx];
      // X[k] * e^{+j*2*pi*k*n/N}  (positive exponent for inverse)
      sum_r += (long long)in_real[k] * c - (long long)in_imag[k] * s;
      sum_i += (long long)in_real[k] * s + (long long)in_imag[k] * c;
    }
    // Divide by N*SCALE = 32*1024 = 32768 = 2^15
    out_real[i] = (int)(sum_r >> 15);
    out_imag[i] = (int)(sum_i >> 15);
  }
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int out_real[32], out_imag[32];

int main( void )
{
  int n = eval_fft_n;

  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  naive_idft( out_real, out_imag,
              eval_in_real, eval_in_imag,
              eval_cos_tbl, eval_sin_tbl, n );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "naive", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < n; i++ ) {
    if ( abs_val(out_real[i] - eval_ref_real[i]) > 1 ||
         abs_val(out_imag[i] - eval_ref_imag[i]) > 1 ) {
      zeppelin_wprintf( L"\n FAILED: naive[%d] = (%d,%d), expected (%d,%d)\n\n",
                     i, out_real[i], out_imag[i],
                     eval_ref_real[i], eval_ref_imag[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

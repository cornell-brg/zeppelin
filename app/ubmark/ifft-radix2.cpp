//========================================================================
// ifft-radix2.cpp
//========================================================================
// Fixed-point inverse FFT benchmark: radix-2 IFFT variant.
//
// The classic fast Fourier transform approach.  Processes data in
// log2(N) = 5 stages of "butterfly" operations, doing O(N*log N) work
// total.  Far fewer instructions overall, but each stage depends on the
// previous one, creating dependency barriers that limit instruction-
// level parallelism.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "ifft.h"

//----------------------------------------------------------------------
// Helpers
//----------------------------------------------------------------------

static int abs_val( int x ) { return x < 0 ? -x : x; }

//----------------------------------------------------------------------
// radix2_ifft -- O(N*log N), butterfly stages
//----------------------------------------------------------------------

__attribute__((noinline))
void radix2_ifft( int* out_real, int* out_imag,
                  int* in_real, int* in_imag,
                  int* cos_tbl, int* sin_tbl, int n, int log2n )
{
  // Copy input to output (will be modified in-place)
  for ( int i = 0; i < n; i++ ) {
    out_real[i] = in_real[i];
    out_imag[i] = in_imag[i];
  }

  // Bit-reversal permutation
  for ( int i = 0; i < n; i++ ) {
    int j = 0;
    for ( int b = 0; b < log2n; b++ )
      if ( i & (1 << b) ) j |= (1 << (log2n - 1 - b));
    if ( j > i ) {
      int tmp;
      tmp = out_real[i]; out_real[i] = out_real[j]; out_real[j] = tmp;
      tmp = out_imag[i]; out_imag[i] = out_imag[j]; out_imag[j] = tmp;
    }
  }

  // Butterfly stages
  for ( int s = 1; s <= log2n; s++ ) {
    int m = 1 << s;
    int half = m >> 1;
    for ( int k = 0; k < n; k += m ) {
      for ( int j = 0; j < half; j++ ) {
        int twiddle_idx = (j * n / m) % n;
        int wr = cos_tbl[twiddle_idx];
        int wi = sin_tbl[twiddle_idx];  // +sin for IFFT
        long long tr = (long long)wr * out_real[k+j+half]
                     - (long long)wi * out_imag[k+j+half];
        long long ti = (long long)wr * out_imag[k+j+half]
                     + (long long)wi * out_real[k+j+half];
        int tr_s = (int)(tr >> 10);  // divide by SCALE=1024
        int ti_s = (int)(ti >> 10);
        int ur = out_real[k+j];
        int ui = out_imag[k+j];
        out_real[k+j]      = ur + tr_s;
        out_imag[k+j]      = ui + ti_s;
        out_real[k+j+half] = ur - tr_s;
        out_imag[k+j+half] = ui - ti_s;
      }
    }
  }

  // Divide by N=32 = 2^5
  for ( int i = 0; i < n; i++ ) {
    out_real[i] >>= 5;
    out_imag[i] >>= 5;
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
  radix2_ifft( out_real, out_imag,
               eval_in_real, eval_in_imag,
               eval_cos_tbl, eval_sin_tbl, n, eval_fft_log2n );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "radix2", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < n; i++ ) {
    if ( abs_val(out_real[i] - eval_ref_real[i]) > 1 ||
         abs_val(out_imag[i] - eval_ref_imag[i]) > 1 ) {
      zeppelin_wprintf( L"\n FAILED: fft[%d] = (%d,%d), expected (%d,%d)\n\n",
                     i, out_real[i], out_imag[i],
                     eval_ref_real[i], eval_ref_imag[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

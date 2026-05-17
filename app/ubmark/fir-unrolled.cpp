//========================================================================
// fir-unrolled.cpp
//========================================================================
// FIR filter benchmark: 4x unrolled variant.
//
// Applies a 16-tap filter to 256 signal samples with a 4x unrolled
// inner loop using four independent accumulators.  The four
// multiply-add chains can execute in parallel across the two multiply
// pipes, roughly doubling the sustained multiply throughput.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "fir.h"

//----------------------------------------------------------------------
// unrolled_fir -- 4x unrolled inner loop, 4 independent accumulators
//----------------------------------------------------------------------

__attribute__((noinline))
void unrolled_fir( int* dst, int* signal, int* coeffs, int nsamp, int ntaps )
{
  int nout = nsamp - ntaps + 1;
  for ( int i = 0; i < nout; i++ ) {
    int s0 = 0, s1 = 0, s2 = 0, s3 = 0;
    for ( int j = 0; j < ntaps; j += 4 ) {
      s0 += signal[i + j]     * coeffs[j];
      s1 += signal[i + j + 1] * coeffs[j + 1];
      s2 += signal[i + j + 2] * coeffs[j + 2];
      s3 += signal[i + j + 3] * coeffs[j + 3];
    }
    dst[i] = s0 + s1 + s2 + s3;
  }
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int dst[241];

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  unrolled_fir( dst, eval_signal, eval_coeffs, eval_nsamp, eval_ntaps );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "unrolled", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < eval_nout; i++ ) {
    if ( dst[i] != eval_ref[i] ) {
      zeppelin_wprintf( L"\n FAILED: unrolled dst[%d] = %d, expected %d\n\n",
                     i, dst[i], eval_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

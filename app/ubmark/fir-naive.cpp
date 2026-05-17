//========================================================================
// fir-naive.cpp
//========================================================================
// FIR filter benchmark: naive variant.
//
// Applies a 16-tap filter to 256 signal samples with one
// multiply-accumulate per inner iteration.  The inner loop has a serial
// dependency chain (each add depends on the previous), limiting the
// processor to one multiply per cycle.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "fir.h"

//----------------------------------------------------------------------
// naive_fir -- one MAC per iteration
//----------------------------------------------------------------------

__attribute__((noinline))
void naive_fir( int* dst, int* signal, int* coeffs, int nsamp, int ntaps )
{
  int nout = nsamp - ntaps + 1;
  for ( int i = 0; i < nout; i++ ) {
    int sum = 0;
    for ( int j = 0; j < ntaps; j++ )
      sum += signal[i + j] * coeffs[j];
    dst[i] = sum;
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
  naive_fir( dst, eval_signal, eval_coeffs, eval_nsamp, eval_ntaps );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "naive", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < eval_nout; i++ ) {
    if ( dst[i] != eval_ref[i] ) {
      zeppelin_wprintf( L"\n FAILED: naive dst[%d] = %d, expected %d\n\n",
                     i, dst[i], eval_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

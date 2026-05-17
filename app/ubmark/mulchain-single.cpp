//========================================================================
// mulchain-single.cpp
//========================================================================
// Multiply-chain microbenchmark: single-chain variant.
//
// Evaluates a degree-7 polynomial via Horner's method on 64 data points.
// One polynomial evaluated serially.  Each multiply depends on the
// previous accumulate, serialising through one MUL pipe.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "mulchain.h"

//----------------------------------------------------------------------
// horner_single -- evaluate one polynomial on all points, sum results
//----------------------------------------------------------------------

__attribute__((noinline))
int horner_single( int* coeff, int* x, int n, int deg )
{
  int sum = 0;
  for ( int i = 0; i < n; i++ ) {
    int val = coeff[deg - 1];
    for ( int d = deg - 2; d >= 0; d-- )
      val = val * x[i] + coeff[d];
    sum += val;
  }
  return sum;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  int result_a = horner_single( eval_coeff_a, eval_x, eval_size, eval_degree );
  int result_b = horner_single( eval_coeff_b, eval_x, eval_size, eval_degree );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "single", t1c - t0c, t1i - t0i );

  if ( result_a != eval_ref_a ) {
    zeppelin_wprintf( L"\n FAILED: single poly_a = %d, expected %d\n\n",
                   result_a, eval_ref_a );
    zeppelin_exit( 1 );
  }
  if ( result_b != eval_ref_b ) {
    zeppelin_wprintf( L"\n FAILED: single poly_b = %d, expected %d\n\n",
                   result_b, eval_ref_b );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}

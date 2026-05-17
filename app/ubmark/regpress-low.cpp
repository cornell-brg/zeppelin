//========================================================================
// regpress-low.cpp
//========================================================================
// Register-pressure microbenchmark: low-pressure variant.
//
// 4 independent accumulators.  Fits comfortably within the rename
// capacity, allowing OOO to overlap iterations.

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "regpress.h"

//----------------------------------------------------------------------
// low_pressure -- 4 accumulators
//----------------------------------------------------------------------

__attribute__((noinline))
void low_pressure( int* data, int n,
                   int* r0, int* r1, int* r2, int* r3 )
{
  int a0 = 0, a1 = 0, a2 = 0, a3 = 0;
  for ( int i = 0; i < n; i++ ) {
    int v = data[i];
    a0 += v;
    a1 ^= v;
    a2 += v * v;
    a3 -= v;
  }
  *r0 = a0; *r1 = a1; *r2 = a2; *r3 = a3;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int lo0, lo1, lo2, lo3;
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  low_pressure( eval_data, eval_size, &lo0, &lo1, &lo2, &lo3 );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "low-pressure", t1c - t0c, t1i - t0i );

  if ( lo0 != eval_ref_lo_a0 || lo1 != eval_ref_lo_a1 ||
       lo2 != eval_ref_lo_a2 || lo3 != eval_ref_lo_a3 ) {
    zeppelin_wprintf( L"\n FAILED: low (%d,%d,%d,%d) != expected (%d,%d,%d,%d)\n\n",
                   lo0, lo1, lo2, lo3,
                   eval_ref_lo_a0, eval_ref_lo_a1, eval_ref_lo_a2, eval_ref_lo_a3 );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}

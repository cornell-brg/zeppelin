//========================================================================
// depchain-multi.cpp
//========================================================================
// Dependency-chain microbenchmark: multi-chain variant.
//
// Computes a dot product with four independent accumulators, each with
// its own load-multiply-add chain.  With OOO issue, loads and multiplies
// from all four chains can overlap.

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "depchain.h"

//----------------------------------------------------------------------
// multi_dot -- four independent chains, exposes ILP
//----------------------------------------------------------------------

__attribute__((noinline))
int multi_dot( int* src0, int* src1, int n )
{
  int acc0 = 0, acc1 = 0, acc2 = 0, acc3 = 0;
  for ( int i = 0; i < n; i += 4 ) {
    acc0 += src0[i]   * src1[i];
    acc1 += src0[i+1] * src1[i+1];
    acc2 += src0[i+2] * src1[i+2];
    acc3 += src0[i+3] * src1[i+3];
  }
  return acc0 + acc1 + acc2 + acc3;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  int result = multi_dot( eval_src0, eval_src1, eval_size );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "multi-chain", t1c - t0c, t1i - t0i );

  if ( result != eval_ref ) {
    zeppelin_wprintf( L"\n FAILED: multi result %d != expected %d\n\n",
                   result, eval_ref );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}

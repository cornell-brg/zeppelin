//========================================================================
// memcopy-compheavy.cpp
//========================================================================
// Load/store bottleneck microbenchmark: compute-heavy variant.
//
// Load one element, apply many ALU/MUL operations, then store.  The
// execution units stay busy between memory ops, achieving much better
// IPC.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "memcopy.h"

//----------------------------------------------------------------------
// compute_heavy -- one load, many ALU/MUL ops, one store per element
//----------------------------------------------------------------------

__attribute__((noinline))
void compute_heavy( int* dst, int* src, int n )
{
  for ( int i = 0; i < n; i++ ) {
    int x = src[i];
    // Multiple independent ALU/MUL operations
    int t1 = x * x;          // MUL
    int t2 = 3 * x;          // MUL
    int t3 = t1 + t2 + 7;    // ALU
    int t4 = t3 ^ 0xAB;      // ALU
    int t5 = x << 2;         // ALU
    int t6 = x >> 1;         // ALU
    dst[i] = t4 + t5 - t6;   // ALU
  }
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int dst[128];

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  compute_heavy( dst, eval_src, eval_size );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "compute-heavy", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < eval_size; i++ ) {
    if ( dst[i] != eval_ref_compute[i] ) {
      zeppelin_wprintf( L"\n FAILED: compute dst[%d] = %d, expected %d\n\n",
                     i, dst[i], eval_ref_compute[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

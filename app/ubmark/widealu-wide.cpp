//========================================================================
// widealu-wide.cpp
//========================================================================
// ALU-pipe saturation microbenchmark: wide variant.
//
// 8x unrolled, 8 independent ALU ops per iteration.  Can keep all 4
// ALU pipes busy.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "widealu.h"

//----------------------------------------------------------------------
// wide_transform -- 8 elements per iteration, independent ALU ops
//----------------------------------------------------------------------

__attribute__((noinline))
void wide_transform( int* dst, int* src, int n, int c1, int c2 )
{
  for ( int i = 0; i < n; i += 8 ) {
    dst[i]   = (src[i]   + c1) ^ c2;
    dst[i+1] = (src[i+1] + c1) ^ c2;
    dst[i+2] = (src[i+2] + c1) ^ c2;
    dst[i+3] = (src[i+3] + c1) ^ c2;
    dst[i+4] = (src[i+4] + c1) ^ c2;
    dst[i+5] = (src[i+5] + c1) ^ c2;
    dst[i+6] = (src[i+6] + c1) ^ c2;
    dst[i+7] = (src[i+7] + c1) ^ c2;
  }
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int dst[256];

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  wide_transform( dst, eval_src, eval_size, eval_c1, eval_c2 );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "wide", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < eval_size; i++ ) {
    if ( dst[i] != eval_ref[i] ) {
      zeppelin_wprintf( L"\n FAILED: wide dst[%d] = %d, expected %d\n\n",
                     i, dst[i], eval_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

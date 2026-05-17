//========================================================================
// widealu-narrow.cpp
//========================================================================
// ALU-pipe saturation microbenchmark: narrow variant.
//
// One element per iteration -- under-utilises the execution resources.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "widealu.h"

//----------------------------------------------------------------------
// narrow_transform -- one element per iteration
//----------------------------------------------------------------------

__attribute__((noinline))
void narrow_transform( int* dst, int* src, int n, int c1, int c2 )
{
  for ( int i = 0; i < n; i++ )
    dst[i] = (src[i] + c1) ^ c2;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int dst[256];

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  narrow_transform( dst, eval_src, eval_size, eval_c1, eval_c2 );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "narrow", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < eval_size; i++ ) {
    if ( dst[i] != eval_ref[i] ) {
      zeppelin_wprintf( L"\n FAILED: narrow dst[%d] = %d, expected %d\n\n",
                     i, dst[i], eval_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

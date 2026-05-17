//========================================================================
// memcopy-memheavy.cpp
//========================================================================
// Load/store bottleneck microbenchmark: memory-heavy variant.
//
// Load-add-store per element.  The single LD/ST pipe is the bottleneck;
// the 4 ALU + 2 MUL pipes sit mostly idle.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "memcopy.h"

//----------------------------------------------------------------------
// mem_heavy -- one load, one add, one store per element
//----------------------------------------------------------------------

__attribute__((noinline))
void mem_heavy( int* dst, int* src, int n )
{
  for ( int i = 0; i < n; i++ )
    dst[i] = src[i] + 7;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int dst[128];

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  mem_heavy( dst, eval_src, eval_size );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "mem-heavy", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < eval_size; i++ ) {
    if ( dst[i] != eval_ref_mem[i] ) {
      zeppelin_wprintf( L"\n FAILED: mem dst[%d] = %d, expected %d\n\n",
                     i, dst[i], eval_ref_mem[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

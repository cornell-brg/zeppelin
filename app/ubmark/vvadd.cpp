//========================================================================
// vvadd.cpp
//========================================================================
// A basic vvadd benchmark for Zeppelin

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "vvadd.h"

void vvadd( int* dest, int* src0, int* src1, int size )
{
  for ( int i = 0; i < size; i++ )
    dest[i] = src0[i] + src1[i];
}

int dest[100];

int main( void )
{
  int start_cycles = zeppelin_cycle_count();
  int start_insts  = zeppelin_inst_count();
  vvadd( dest, eval_src0, eval_src1, eval_size );
  int end_cycles = zeppelin_cycle_count();
  int end_insts  = zeppelin_inst_count();

  int num_cycles = end_cycles - start_cycles;
  int num_insts  = end_insts  - start_insts;
  ubmark_stats_print( "vvadd", num_cycles, num_insts );
  for ( int i = 0; i < eval_size; i++ ) {
    if ( dest[i] != eval_ref[i] ) {
      zeppelin_wprintf(
          L"\n FAILED: dest[%d] != eval_ref[%d] (%d != %d)\n\n", i, i,
          dest[i], eval_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"All indices match!\n" );
}
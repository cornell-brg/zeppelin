//========================================================================
// depchain-serial.cpp
//========================================================================
// Dependency-chain microbenchmark: serial variant.
//
// Computes a dot product with a single accumulator, one
// load-multiply-add chain.  Every multiply depends on the previous
// iteration's accumulate, and every load feeds directly into a multiply.
// There is almost no independent work for OOO to exploit.

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "depchain.h"

//----------------------------------------------------------------------
// serial_dot -- single chain, no ILP
//----------------------------------------------------------------------

__attribute__((noinline))
int serial_dot( int* src0, int* src1, int n )
{
  int acc = 0;
  for ( int i = 0; i < n; i++ )
    acc += src0[i] * src1[i];
  return acc;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  int result = serial_dot( eval_src0, eval_src1, eval_size );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "serial", t1c - t0c, t1i - t0i );

  if ( result != eval_ref ) {
    zeppelin_wprintf( L"\n FAILED: serial result %d != expected %d\n\n",
                   result, eval_ref );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}

//========================================================================
// ptrchase-onechain.cpp
//========================================================================
// Pointer-chase microbenchmark: single chain variant (baseline).
//
// Single pointer-chase traversal through a 32-element permutation.

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "ptrchase.h"

//----------------------------------------------------------------------
// one_chain -- single pointer-chase traversal (baseline)
//----------------------------------------------------------------------

__attribute__((noinline))
int one_chain( int* chain, int n )
{
  int idx = 0;
  int sum = 0;
  for ( int i = 0; i < n; i++ ) {
    idx  = chain[idx];
    sum += idx;
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
  int r = one_chain( chain_a, chase_len );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "one-chain", t1c - t0c, t1i - t0i );

  if ( r != chain_ref ) {
    zeppelin_wprintf( L"\n FAILED: one chain %d != %d\n\n", r, chain_ref );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}

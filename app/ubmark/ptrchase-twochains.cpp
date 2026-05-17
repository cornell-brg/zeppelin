//========================================================================
// ptrchase-twochains.cpp
//========================================================================
// Pointer-chase microbenchmark: two-chain variant.
//
// Two independent pointer chases interleaved in the same loop.  With
// OOO issue, chain-B's load can bypass chain-A's blocked load and issue
// immediately.  Both chains progress in parallel, so the cycle count
// stays close to the one-chain baseline.

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "ptrchase.h"

//----------------------------------------------------------------------
// two_chains -- two independent pointer chases in one loop
//----------------------------------------------------------------------

__attribute__((noinline))
int two_chains( int* ca, int* cb, int n )
{
  int a = 0, b = 0;
  int sum_a = 0, sum_b = 0;
  for ( int i = 0; i < n; i++ ) {
    a = ca[a];
    sum_a += a;
    b = cb[b];
    sum_b += b;
  }
  return sum_a + sum_b;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  int r = two_chains( chain_a, chain_b, chase_len );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "two-chains", t1c - t0c, t1i - t0i );

  if ( r != chain_ref + chain_ref ) {
    zeppelin_wprintf( L"\n FAILED: two chains %d != %d\n\n",
                   r, chain_ref + chain_ref );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}

//========================================================================
// branchloop-branchy.cpp
//========================================================================
// Branch-misprediction microbenchmark: branchy variant.
//
// Classifies 128 integers into three bins (lo, mid, hi) using if/else
// chains.  Each data-dependent branch that goes the wrong way causes a
// full pipeline squash.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "branchloop.h"

//----------------------------------------------------------------------
// classify_branchy -- if/else classification
//----------------------------------------------------------------------

__attribute__((noinline))
void classify_branchy( int* data, int n, int tlo, int thi,
                       int* cnt_lo, int* cnt_mid, int* cnt_hi )
{
  int lo = 0, mid = 0, hi = 0;
  for ( int i = 0; i < n; i++ ) {
    if ( data[i] < tlo )
      lo++;
    else if ( data[i] < thi )
      mid++;
    else
      hi++;
  }
  *cnt_lo  = lo;
  *cnt_mid = mid;
  *cnt_hi  = hi;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int blo, bmid, bhi;
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  classify_branchy( eval_data, eval_size, eval_thresh_lo, eval_thresh_hi,
                    &blo, &bmid, &bhi );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "branchy", t1c - t0c, t1i - t0i );

  if ( blo != eval_ref_lo || bmid != eval_ref_mid || bhi != eval_ref_hi ) {
    zeppelin_wprintf( L"\n FAILED: branchy counts (%d,%d,%d) != expected (%d,%d,%d)\n\n",
                   blo, bmid, bhi, eval_ref_lo, eval_ref_mid, eval_ref_hi );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}

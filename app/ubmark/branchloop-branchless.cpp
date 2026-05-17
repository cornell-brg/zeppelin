//========================================================================
// branchloop-branchless.cpp
//========================================================================
// Branch-misprediction microbenchmark: branchless variant.
//
// Classifies 128 integers into three bins (lo, mid, hi) using
// arithmetic masking to compute bin membership without any conditional
// branches.  The pipeline never squashes.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "branchloop.h"

//----------------------------------------------------------------------
// classify_branchless -- arithmetic masking, no branches
//----------------------------------------------------------------------

__attribute__((noinline))
void classify_branchless( int* data, int n, int tlo, int thi,
                          int* cnt_lo, int* cnt_mid, int* cnt_hi )
{
  int lo = 0, mid = 0, hi = 0;
  for ( int i = 0; i < n; i++ ) {
    int v = data[i];
    // (v - tlo) >> 31 gives -1 if v < tlo, 0 otherwise (arithmetic shift)
    int below_lo = (v - tlo) >> 31;   // -1 if v < tlo, else 0
    int below_hi = (v - thi) >> 31;   // -1 if v < thi, else 0
    // below_lo == -1 => lo bin
    // below_lo == 0 && below_hi == -1 => mid bin
    // below_hi == 0 => hi bin
    lo  += below_lo & 1;                        // 1 if v < tlo
    mid += (~below_lo) & below_hi & 1;          // 1 if tlo <= v < thi
    hi  += (~below_lo) & (~below_hi) & 1;       // 1 if v >= thi
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
  int nlo, nmid, nhi;
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  classify_branchless( eval_data, eval_size, eval_thresh_lo, eval_thresh_hi,
                       &nlo, &nmid, &nhi );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "branchless", t1c - t0c, t1i - t0i );

  if ( nlo != eval_ref_lo || nmid != eval_ref_mid || nhi != eval_ref_hi ) {
    zeppelin_wprintf( L"\n FAILED: branchless counts (%d,%d,%d) != expected (%d,%d,%d)\n\n",
                   nlo, nmid, nhi, eval_ref_lo, eval_ref_mid, eval_ref_hi );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}

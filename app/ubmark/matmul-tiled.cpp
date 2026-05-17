//========================================================================
// matmul-tiled.cpp
//========================================================================
// Integer matrix multiply benchmark: 2x2 tiled variant.
//
// 2x2 tile with 4 independent accumulators in the inner loop.  The four
// multiply-add chains are independent, so out-of-order issue and the two
// multiply pipes can overlap them.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "matmul.h"

//----------------------------------------------------------------------
// tiled_matmul -- 2x2 tiled with 4 independent accumulators
//----------------------------------------------------------------------

__attribute__((noinline))
void tiled_matmul( int* dst, int* a, int* b, int n )
{
  // Zero destination
  for ( int i = 0; i < n * n; i++ )
    dst[i] = 0;

  // 2x2 tiling: process 2 rows of A and 2 columns of B at a time
  for ( int i = 0; i < n; i += 2 ) {
    for ( int j = 0; j < n; j += 2 ) {
      int s00 = 0, s01 = 0, s10 = 0, s11 = 0;
      for ( int k = 0; k < n; k++ ) {
        int a0k = a[i*n + k];
        int a1k = a[(i+1)*n + k];
        int bk0 = b[k*n + j];
        int bk1 = b[k*n + j + 1];
        s00 += a0k * bk0;
        s01 += a0k * bk1;
        s10 += a1k * bk0;
        s11 += a1k * bk1;
      }
      dst[i*n + j]       = s00;
      dst[i*n + j + 1]   = s01;
      dst[(i+1)*n + j]   = s10;
      dst[(i+1)*n + j + 1] = s11;
    }
  }
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int dst[256];

int main( void )
{
  int n = eval_mat_n;

  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  tiled_matmul( dst, eval_mat_a, eval_mat_b, n );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "tiled", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < n * n; i++ ) {
    if ( dst[i] != eval_ref[i] ) {
      zeppelin_wprintf( L"\n FAILED: tiled dst[%d] = %d, expected %d\n\n",
                     i, dst[i], eval_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

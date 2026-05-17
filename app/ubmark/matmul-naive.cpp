//========================================================================
// matmul-naive.cpp
//========================================================================
// Integer matrix multiply benchmark: naive variant.
//
// Standard triple-nested loop (i,j,k).  One multiply-add per inner
// iteration -- limited instruction-level parallelism.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "matmul.h"

//----------------------------------------------------------------------
// naive_matmul -- standard ijk loop
//----------------------------------------------------------------------

__attribute__((noinline))
void naive_matmul( int* dst, int* a, int* b, int n )
{
  for ( int i = 0; i < n; i++ ) {
    for ( int j = 0; j < n; j++ ) {
      int sum = 0;
      for ( int k = 0; k < n; k++ )
        sum += a[i*n + k] * b[k*n + j];
      dst[i*n + j] = sum;
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
  naive_matmul( dst, eval_mat_a, eval_mat_b, n );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "naive", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < n * n; i++ ) {
    if ( dst[i] != eval_ref[i] ) {
      zeppelin_wprintf( L"\n FAILED: naive dst[%d] = %d, expected %d\n\n",
                     i, dst[i], eval_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

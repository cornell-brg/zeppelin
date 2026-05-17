//========================================================================
// isortsearch-selection.cpp
//========================================================================
// Sorting microbenchmark: selection sort variant.
//
// Inner loop scans for the minimum using only loads and compares (no
// stores until the final swap).  The OOO issue queue can overlap
// independent loads with ALU comparisons.

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "isortsearch.h"

//----------------------------------------------------------------------
// selection_sort
//----------------------------------------------------------------------

__attribute__((noinline))
void selection_sort( int* arr, int n )
{
  for ( int i = 0; i < n - 1; i++ ) {
    int min_idx = i;
    for ( int j = i + 1; j < n; j++ ) {
      if ( arr[j] < arr[min_idx] )
        min_idx = j;
    }
    // Single swap at end
    int tmp = arr[i];
    arr[i] = arr[min_idx];
    arr[min_idx] = tmp;
  }
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int arr[64];

int main( void )
{
  for ( int i = 0; i < eval_size; i++ )
    arr[i] = eval_isort_src[i];

  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  selection_sort( arr, eval_size );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "selection", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < eval_size; i++ ) {
    if ( arr[i] != eval_isort_ref[i] ) {
      zeppelin_wprintf( L"\n FAILED: ssort[%d] = %d, expected %d\n\n",
                     i, arr[i], eval_isort_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

//========================================================================
// isortsearch-insertion.cpp
//========================================================================
// Sorting microbenchmark: insertion sort variant.
//
// Inner loop shifts elements right with a data-dependent branch, a load
// and store per shift, and serial dependencies.  Worst case for a
// processor with no branch predictor and a single LD/ST unit.

#include "utils/zeppelin_stdlib.h"
#include "utils/zeppelin_wprintf.h"
#include "ubmark_stats.h"
#include "isortsearch.h"

//----------------------------------------------------------------------
// insertion_sort
//----------------------------------------------------------------------

__attribute__((noinline))
void insertion_sort( int* arr, int n )
{
  for ( int i = 1; i < n; i++ ) {
    int key = arr[i];
    int j = i - 1;
    while ( j >= 0 && arr[j] > key ) {
      arr[j + 1] = arr[j];
      j--;
    }
    arr[j + 1] = key;
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
  insertion_sort( arr, eval_size );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "insertion", t1c - t0c, t1i - t0i );

  for ( int i = 0; i < eval_size; i++ ) {
    if ( arr[i] != eval_isort_ref[i] ) {
      zeppelin_wprintf( L"\n FAILED: isort[%d] = %d, expected %d\n\n",
                     i, arr[i], eval_isort_ref[i] );
      zeppelin_exit( 1 );
    }
  }
  zeppelin_wprintf( L"Results match!\n" );
}

//========================================================================
// stringsearch-firstchar.cpp
//========================================================================
// Substring search benchmark: first-character filter variant.
//
// First checks only the first character of the pattern at each position;
// only when it matches does it compare the full pattern.  This reduces
// the total number of byte comparisons by skipping positions where the
// first character already differs, cutting down on branch
// mispredictions.

#include "utils/zeppelin_stdlib.h"
#include "ubmark_stats.h"
#include "utils/zeppelin_wprintf.h"
#include "stringsearch.h"

//----------------------------------------------------------------------
// firstchar_search -- filter on first char before full comparison
//----------------------------------------------------------------------

__attribute__((noinline))
int firstchar_search( const char* text, int text_len,
                      const char* pattern, int pat_len )
{
  int count = 0;
  int limit = text_len - pat_len;
  char first = pattern[0];
  for ( int i = 0; i <= limit; i++ ) {
    if ( text[i] != first )
      continue;
    int match = 1;
    for ( int j = 1; j < pat_len; j++ ) {
      if ( text[i + j] != pattern[j] ) {
        match = 0;
        break;
      }
    }
    count += match;
  }
  return count;
}

//----------------------------------------------------------------------
// main
//----------------------------------------------------------------------

int main( void )
{
  int t0c = zeppelin_cycle_count();
  int t0i = zeppelin_inst_count();
  int result = firstchar_search( eval_text, eval_text_len,
                                 eval_pattern, eval_pattern_len );
  int t1c = zeppelin_cycle_count();
  int t1i = zeppelin_inst_count();

  ubmark_stats_print( "firstchar", t1c - t0c, t1i - t0i );

  if ( result != eval_ref_count ) {
    zeppelin_wprintf( L"\n FAILED: firstchar count = %d, expected %d\n\n",
                   result, eval_ref_count );
    zeppelin_exit( 1 );
  }
  zeppelin_wprintf( L"Results match!\n" );
}
